#!/usr/bin/env zsh
#
# 引数に応じてコマンド実行を処理するスクリプト
# ワークフローの処理分岐用に output をおこなう wrapper を含む
#
######################################################################

# SAVE_LOG=1 でコマンド実行時のログを保存するようになる
# また、エラー発生時に open コマンドで当該ログを開くようになる
SAVE_LOG=1

######################################################################
# 環境変数周りの処理

# 以下は必要に応じて以下コメントアウトしてください
#
# PATH=/usr/local/bin:$PATH
# source ${ZDOTDIR:-~}/.zprofile
#

# 各種データ保存用ディレクトリ
DATA_DIR="${alfred_workflow_data:-./}"
#
# $alfred_workflow_data の例
# $HOME/Library/Application Support/Alfred/Workflow Data/com.github.kiyohara.alfred-workflow-boilerplate
#

DATE=`date +%Y%m%d-%H%M%S`

######################################################################
# functions

main() {
  cmd=$1 && shift

  case "$cmd" in
    date) exec_date ;;
    say) exec_say $@;;
    error_test) exec_error_test;;
    *) unknown $cmd $@;;
  esac
}

exec_date() {
  common DATE echo `LANG=ja_JP.UTF-8 date`
}

exec_say() {
  if [[ ${#@} > 0 ]];then
    common DATE say $@
  else
    common DATE echo Argument required
  fi
}

exec_error_test() {
  common ERROR_TEST ./error_test.sh
}

######################################################################
# utils

# ERROR:: を付けて echo する
# 後のワークフローで ERROR:: 部をエラー判定に利用している
echo_err() {
  echo ERROR::$@
}

# SUCCESS:: を付けて echo する
echo_success() {
  echo SUCCESS::$@
}

# ログファイル名を決める
# 引数付きの場合は引数をプリフィックスに使う
log_file() {
  path="$DATA_DIR/$DATE"
  if [[ ${#@} > 0 ]];then
    path="$path-$@[1]"
  fi
  path="$path-log.txt"

  echo $path
}

# ログファイルへの書き込み
write_log() {
  log_file=$@[1] && shift
  echo $@ >> $log_file
}

# コマンド実行の wrapper
# 主にエラー処理とロギング処理をおこなう
# 後のワークフローでより細かな制御をおこなうために STDOUT 経由で情報を送付して
# いる
#
# common <log_file prefix> <commands..>
#
common() {
  if [[ ${#@} < 2 ]];then
    echo_err invalid argument: common $@
    return 1
  fi

  ### ログファイルの処理 ###
  log_file=`log_file $@[1]` && shift

  # ログディレクトリの作成
  log_dir=`dirname $log_file`
  [[ -n "$log_dir" ]] && [[ ! -d $log_dir ]] && mkdir -p $log_dir

  # 実行するコマンドラインを記録
  write_log $log_file "*** EXEC ***"
  write_log $log_file $@

  ### コマンドの実行 ###
  # 出力保存用の tmp ファイルの作成
  output_file=`mktemp`

  # 実行
  $@ > $output_file 2>&1
  ret=$?

  # 実行結果のログ保存
  write_log $log_file
  write_log $log_file "*** STDOUT/STDERR ***"
  cat $output_file >> $log_file

  ### コマンド結果の処理 ###
  if [[ $ret == 0 ]]; then # status code で判定
    if [[ -s $output_file ]]; then # 出力あるなら
      echo_success `cat $output_file`
    else
      echo_success `echo $@`
    fi
    [[ $SAVE_LOG != 1 ]] && rm $log_file
  else
    if [[ $SAVE_LOG == 1 ]]; then
      write_log $log_file
      write_log $log_file "*** ENV ***"
      env >> $log_file

      echo_err logfile::$log_file
    else
      echo_err `cat $log_file`
      rm $log_file
    fi
  fi

  rm $output_file
  return $ret
}

unknown() {
  echo_err "unknown command: $@"
}

######################################################################
# execute

main $@
