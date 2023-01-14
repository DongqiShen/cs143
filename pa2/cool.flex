/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
CLASS           class
ELSE            else
FI              fi
IF              if
IN              in
INHERITS        inherits
LET             let
LOOP            loop
POOL            pool
THEN            then
WHILE           while
CASE            case
ESAC            esac
OF              of
NEW             new
ISVOID          isvoid
ASSIGN          <-
NOT             not
LE              <=

%x      COMMENT
%x      STRING
%x      STRING_ESCAPE

%%

 /*
  *  Nested comments
  */

  /* 单行注释 */
--.*$ {}

"(*"  { BEGIN(COMMENT); }
"*)"  {
    cool_yylval.error_msg = "Unmatched *)";
    return (ERROR);
}

<COMMENT><<EOF>> {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return (ERROR);
}

<COMMENT>\n {  curr_lineno++;  }

<COMMENT>"*)" {
    BEGIN(INITIAL);
}

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{LE} { return (LE); }
{ASSIGN} { return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
  /* 关键字 */

{CLASS} { return (CLASS); }
{ELSE} { return (ELSE); }
{FI} { return (FI); }
{IF} { return (IF); }
{IN} { return (IN); }
{INHERITS} { return (INHERITS); }
{LET} { return (LET); }
{LOOP} { return (LOOP); }
{POOL} { return (POOL); }
{THEN} { return (THEN); }
{WHILE} { return (WHILE); }
{CASE} { return (CASE); }
{ESAC} { return (ESAC); }
{OF} { return (OF); }
{NEW} { return (NEW); }
{ISVOID} { return (ISVOID); }
{NOT} { return (NOT); }

  /*  bool类型  */
t[Rr][Uu][Ee]   { cool_yylval.boolean = true; return (BOOL_CONST); }
f[Aa][Ll][Ss][Ee] { cool_yylval.boolean = false; return (BOOL_CONST); }

  /*  类名和变量名  */
[A-Z_][a-zA-Z0-9_]* { 
  cool_yylval.symbol = idtable.add_string(yytext, yyleng);
  return (TYPEID);
}
[a-z_][a-zA_Z0-9_]* {
  cool_yylval.symbol = idtable.add_string(yytext, yyleng);
  return (OBJECTID);
}

  /* 整数 */
[0-9][0-9]*     { cool_yylval.symbol = inttable.add_string(yytext); return (INT_CONST);}
 


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\" {
  string_buf_ptr = string_buf;
  BEGIN(STRING);
}

<STRING><<EOF>> {
	  BEGIN(INITIAL);
	  cool_yylval.error_msg = "EOF in string constant";
	  return ERROR;
}

<STRING>\n {
    ++curr_lineno;
    BEGIN(INITIAL);
	  cool_yylval.error_msg = "Unterminated string constant";
	  return ERROR;
}

<STRING>\0 {
	  BEGIN(INITIAL);
	  cool_yylval.error_msg = "String contains null character";
	  return ERROR;
}

<STRING>\" {
    BEGIN(INITIAL);
    *string_buf_ptr = '\0';
    cool_yylval.symbol = stringtable.add_string(string_buf);
    return (STR_CONST);
}

<STRING>\\n {
	  if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		    BEGIN(INITIAL);
		    cool_yylval.error_msg = "String constant too long";
		    return ERROR;
	  }
	  *string_buf_ptr++ = '\n';
}

<STRING>\\t {
    if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST - 1]) {
        BEGIN(INITIAL);
        cool_yylval.error_msg = "String constant too long";
        return ERROR;
    }
    *string_buf_ptr++ = '\t';
}

<STRING>\\b {
    if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST - 1]) {
        BEGIN(INITIAL);
        cool_yylval.error_msg = "String constant too long";
        return ERROR;
    }
    *string_buf_ptr++ = '\b';
}

<STRING>\\f {
    if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST - 1]) {
        BEGIN(INITIAL);
        cool_yylval.error_msg = "String constant too long";
        return ERROR;
    }
    *string_buf_ptr++ = '\f';
}

<STRING>\\(.|\n)	{
	  if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
		    BEGIN(INITIAL);
		    cool_yylval.error_msg = "String constant too long";
		  return ERROR;
	  }
	  *string_buf_ptr++ = yytext[1];
}

<STRING>[^\\\n\"]+ {
	  char *yptr = yytext;
	  while ( *yptr ) {
		  if ((string_buf_ptr - 1) == &string_buf[MAX_STR_CONST-1]) {
			  BEGIN(INITIAL);
			  cool_yylval.error_msg = "String constant too long";
			  return ERROR;
		  }
		  *string_buf_ptr++ = *yptr++;
	  }
}



  /*  单个合法字符和非法字符  */
[\[\]\'>] {
    cool_yylval.error_msg = yytext;
    return (ERROR);
}

[ \t\f\r\v]  {}
\n { ++curr_lineno; }


. {
    return yytext[0];
}

%%
