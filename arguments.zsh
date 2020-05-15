#!/usr/bin/env zsh
#
# 引数候補をリスティング & 入力をフィルタするためのスクリプト
# STDIN に応じて候補リストを JSON として STDOUT に出力する
#
# 後述 JSON の arg の内容を次のフローに渡す点に注意
# 例えば、 date の後ろにいくら文字列を連ねても、次のフローに渡る query
# は date のみ
# 逆に say の部分ではあらゆる入力をパススルーしている
#
######################################################################

main() {
  cmd=$@[1]
  items=()

  # 引数が与えられていないときは全てを表示する
  all=false && [[ ${#@} == 0 ]] && all=true

  # date: 日付読み上げコマンド
  $all || [[ date == $cmd* ]] && items=($items $date_json)

  # say: say コマンドの実行
  $all || [[ say == $cmd* ]] && items=($items $say_json)

  # error test: エラーテストコマンド
  $all || [[ error_test == $cmd* ]] && items=($items $error_test_json)

  # JSON の出力
  # (j.,.) は , でリストを結合している
  cat <<EOF
{
  "items": [
    ${(j.,.)items}
  ]
}
EOF

}

######################################################################
# JSON

# パススルーするための文字列構築
# JSON の値とするために " をエスケープ
escaped_query=`echo "$@" | sed 's/"/\\\\"/g'`

date_json=`cat <<EOF
{
  "title": "date",
  "subtitle": "voice out current date",
  "arg": "date",
  "autocomplete": "date",
  "icon": {
    "path": "calendar.png"
  }
}
EOF`

say_json=`cat <<EOF
{
  "title": "say",
  "subtitle": "execute say command with arguments",
  "autocomplete": "say ",
  "arg": "$escaped_query",
  "icon": {
    "path": "speaker.png"
  }
}
EOF`

error_test_json=`cat <<EOF
{
  "title": "error test",
  "subtitle": "test execution error",
  "arg": "error_test",
  "autocomplete": "error_test",
  "icon": {
    "path": "ghost.png"
  }
}
EOF`

######################################################################
# execute

main $@
