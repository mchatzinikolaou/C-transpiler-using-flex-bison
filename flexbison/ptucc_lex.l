%{
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ptucc_parser.tab.h"
#include "cgen.h"

int line_num = 1;

/* 
	A primitive macro facility:
	just one macro is allowed to be defined! 
*/
#define MAXMACRO 32
char* mactable[MAXMACRO][2];
int mactable_size = 0;

/* Return 1 on success, 0 on failure (macro table full) */
int set_macro(char* name, char* def);

/* Return def for macro, or NULL if no such macro is defined. */
char* get_macro(char* name);

%}


ESCAPE 	"\\n"|"\\t"|"\\r"|"\\\\"|"\\\'"|"\\\""

BOOL "true"|"false"



SIGN "+"|"-"
RELATIONAL  	">="|"<="|">"|"<"

DIGIT  [0-9]
NUMBER  "0"|[1-9]{DIGIT}*
REAL 	{NUMBER}"."{DIGIT}+([Ee]{SIGN}?{NUMBER})?
ID [a-zA-Z][0-9a-zA-Z_]*


STRING  '([^'\n]|{ESCAPE})*'|\"([^'\n]|{ESCAPE})*\"  	





%x comment
%x line_comment
%x macro



%x string_small
%x string_big



/*\' 	BEGIN(string_small);
<string_small>.		{
					//grow the string to be returned
				}

<string_small>\' 		{
					//return the string.
					BEGIN(INITIAL);
				}

\" 	BEGIN(string_big);
<string_big>.			{
					//grow string
				}

<string_big>(\"|\n) 		{
					//return string.
					BEGIN (INITIAL);
				}*/

%%

@defmacro[ \r\t]+       BEGIN(macro);
<macro>{ID}             {




	


							/* Store macro name */
							char* name = strdup(yytext);
							char* def = NULL;
							size_t deflen = 0;
							char c;

							FILE* deff = open_memstream(&def, &deflen);

							while((c=input())!='\n')
							   fputc(c, deff);
							fclose(deff);

							if(!set_macro(name, def))
								yyerror("lexer error: failed to define macro '%s'\n", name);
							BEGIN(INITIAL);
						};




div|"/"		return KW_DIV;
function	return KW_FUNC;
mod		return KW_MOD;
procedure	return KW_PROC;
result		return KW_RESULT;
array		return KW_ARRAY;
do 		return KW_DO;
goto		return KW_GOTO;
and|"&&"	return KW_AND;
not|"!"		return KW_NOT;
or|"||"		return KW_OR;
program 	return KW_PROGRAM;
return 		{ yylval.str = strdup(yytext); return KW_RETURN; }
boolean 	return KW_BOOLEAN;
else		return KW_ELSE;
if 		return KW_IF;
of		return KW_OF;
real 		return KW_REAL;
then		return KW_THEN;
char		return KW_CHAR;
for 		return KW_FOR;
integer 		return KW_INTEGER;
repeat 		return KW_REPEAT;
until 		return KW_UNTIL;
begin		return KW_BEGIN;
end		return KW_END;
var		return KW_VAR;
while 		return KW_WHILE;
to		return KW_TO;
downto 	return KW_DOWNTO;
type 		return KW_TYPE;


{RELATIONAL}			{ yylval.str = strdup(yytext); return RELATIONAL; }
{BOOL}			{ yylval.str = strdup(yytext); return BOOL; }
				
{NUMBER}			{ yylval.str = strdup(yytext); return POSINT; }
{REAL}				{ yylval.str = strdup(yytext); return REAL; }
{ID}  				{
						//Get macro of this identifier
					   char* def = get_macro(yytext);
					   //If the macro is not taken return this identifier
					   if(def==NULL) {
					   		yylval.str = strdup(yytext);
					   		return IDENT;
					   	}
					   //MAYBE SEE THIS CODE LATER ON
					   for(int i=strlen(def); i>0; i--) {
					   	  unput(def[i-1]);
					   }
				} 
{STRING}			{ yylval.str = strdup(yytext); return STRING; }

"="				return TK_EQUAL;
":"				return ':';
":="				return STORE;
","				return ',';
"+"				{ yylval.str = strdup(yytext); return TK_SIGN; }
"-"				{ yylval.str = strdup(yytext); return TK_SIGN; }
"<>"				{ yylval.str = "!="; return RELATIONAL; }	
"*"				return TK_MULTIPLY;
";"				return ';';
"."				return '.';
"("				return '(';
")"				return ')';
"["				return '[';
"]"				return ']';
"{"				return '{';
"}"				return '}';

"(*"					BEGIN(comment);
<comment>[^*\n]*        /* eat anything that's not a '*' */
<comment>"*"+[^*)\n]*   /* eat up '*'s not followed by ')'s */
<comment>\n             ++line_num;
<comment><<EOF>>	{
					fprintf(stderr,"Unterminated comment!\n");
					return -1;
}
<comment>"*"+")"        BEGIN(INITIAL);

"//"	BEGIN(line_comment);
<line_comment>[^\n]
<line_comment>[\n] 	{
				++line_num;
				BEGIN(INITIAL);
			}





[ \r\t]					/* skip whitespace */
\n 						++line_num;
<<EOF>> 				return EOF;

.        { yyerror("lexical error: unrecognized literal '%s'\n", yytext); }


%%

int set_macro(char* name, char* def)
{
	/* Check to see if macro already defined, and redefine it. */
	int i;
	for(i=0; i<mactable_size; i++) {
		if(strcmp(mactable[i][0], name)==0) {
			/* found ! */
			free(name);
			free(mactable[i][1]);
			mactable[i][1] = def;
			break;
		}
	}
	if(i<mactable_size)
		return 1;
	else if(mactable_size < MAXMACRO) {
		/* new entry */
		assert(i==mactable_size);
		mactable[i][0] = name;
		mactable[i][1] = def;
		mactable_size++;
		return 1;
	}
	else
		return 0;
}

char* get_macro(char* name)
{
	for(int i=0;i<mactable_size; i++) {
		if(strcmp(mactable[i][0], name)==0)
			return mactable[i][1];
	}
	return NULL;
}