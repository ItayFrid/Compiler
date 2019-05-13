if  [[ $1 = "-d" ]]; then
  rm y.tab.c y.tab.h lex.yy.c file y.output
elif [[ $1 = "-r" ]]; then
  ./file<file.t
elif [[ $1 = "--debug" ]]; then
  yacc -d file.y --debug --verbose
  lex file.l
  cc -o file y.tab.c
else
  yacc -d file.y --debug --verbose
  yacc -d file.y
  lex file.l
  cc -o file y.tab.c
fi