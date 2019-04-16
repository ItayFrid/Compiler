if  [[ $1 = "-d" ]]; then
  rm y.tab.c y.tab.h lex.yy.c file
elif [[ $1 = "-r" ]]; then
  ./file<file.t
else
  yacc -d file.y
  lex file.l
  cc -o file y.tab.c
fi