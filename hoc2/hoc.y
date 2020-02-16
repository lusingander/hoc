%{
double  mem[26];

int yylex(void);
void yyerror(char*);
void warning(char*, char*);
int printf(const char *, ...);
double fmod(double, double);
int fpecatch(void);
void execerror(char* s, char* t);
%}
%union  {
    double  val;
    int     index;
}
%token  <val>   NUMBER
%token  <index> VAR
%type   <val>   expr
%right  '='
%left   '+' '-'
%left   '*' '/' '%'
%left   UNARYPLUS
%left   UNARYMINUS
%%
list:     /* nothing */
        | list '\n'
        | list expr '\n'    { printf("\t%.8g\n", $2); }
        | list error '\n'   { yyerrok; }
        ;
expr:     NUMBER
        | VAR           { $$ = mem[$1]; }
        | VAR '=' expr  { $$ = mem[$1] = $3; }
        | '+' expr  %prec UNARYPLUS { $$ = $2; }
        | '-' expr  %prec UNARYMINUS { $$ = -$2; }
        | expr '+' expr { $$ = $1 + $3; }
        | expr '-' expr { $$ = $1 - $3; }
        | expr '*' expr { $$ = $1 * $3; }
        | expr '/' expr {
                    if ($3 == 0.0)
                        execerror("division by zero", "");
                    $$ = $1 / $3; }
        | expr '%' expr { $$ = fmod($1, $3); }
        | '(' expr ')'  { $$ = $2; }
        ;
%%
#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <signal.h>
#include <setjmp.h>

char    *progname;
int     lineno = 1;
jmp_buf begin;

int main(int argc, char** argv)
{
    int fpecatch();

    progname = argv[0];
    setjmp(begin);
    signal(SIGFPE, fpecatch);
    yyparse();

    return 0;
}

void execerror(char* s, char* t)
{
    warning(s, t);
    longjmp(begin, 0);
}

int fpecatch(void)
{
    execerror("floating point exception", (char*)0);
}

int yylex(void)
{
    int c;

    while ((c = getchar()) == ' ' || c == '\t')
        ;
    if (c == EOF)
        return 0;
    if (c == '.' || isdigit(c))
    {
        ungetc(c, stdin);
        scanf("%lf", &yylval.val);
        return NUMBER;
    }
    if (islower(c))
    {
        yylval.index = c - 'a';
        return VAR;
    }
    if (c == '\n')
        lineno++;
    return c;
}

void yyerror(char* s)
{
    warning(s, (char*)0);
}

void warning(char* s, char* t)
{
    fprintf(stderr, "%s: %s", progname, s);
    if (t)
        fprintf(stderr, " %s", t);
    fprintf(stderr, " near line %d\n", lineno);
}

