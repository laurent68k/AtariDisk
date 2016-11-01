//
//  LFTextFormatter.m
//
//  Created by Laurent on 01/06/2012.
//  Copyright 2012 Laurent68k. All rights reserved.
//
//	Operating System:	OSX 10.6 Snow Leopard
//	Xcode:				3.2.6
//	In memory of Steve Jobs, February 24, 1955 - October 5, 2011.

#import "LFTextFormatter.h"


@implementation LFTextFormatter

//---------------------------------------------------------------------------
-(id) initWithlenght:(UInt32)lenght {

    if (self = [super init]) {
        
        self->stringlength = lenght;
        
	}           
    return self;
}
//---------------------------------------------------------------------------
- (NSString *)stringForObjectValue:(id)string {

	return(string);
}
//---------------------------------------------------------------------------- 
-(BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString  **)error {

    *obj = string;
    return true;
}
//---------------------------------------------------------------------------
-(BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
	
    NSRange foundRange;
	
	NSCharacterSet *disallowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789QWERTYUIOPLKJHGFDSAZXCVBNMqwertyuioplkjhgfdsazxcvbnm_-"] invertedSet];
	foundRange = [partialString rangeOfCharacterFromSet:disallowedCharacters];
	
	//	if we have found an illegal character or length > max allowed
	if( foundRange.location != NSNotFound || [partialString length] > self->stringlength) 	{
        NSBeep();
        return false;
	}

     return true;
	
	/*NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^([A-Za-z0-9\\-\\+\\!\\#\\$\\%\\&\\'\\(\\)\\@\\^\\_\\{\\}\\~){1,8}(\\.)?([0-9A-Za-z\\-\\+\\!\\#\\$\\%\\&\\'\\(\\)\\@\\^\\_\\{\\}\\~)){0,3}" options:NSRegularExpressionSearch | NSRegularExpressionCaseInsensitive error:nil];
 
	// search for matches
	NSUInteger numberOfMatches = [regex numberOfMatchesInString:partialString options:0 range:NSMakeRange(0, [partialString length])];
	 
	if (numberOfMatches > 0 ) {
		return true;
	}
	else {               
		NSBeep();
        return false;
	}*/
}

@end

/*

Regular Expression Metacharacters

Character	outside
of sets	[inside sets]	Description
\a	?	?	Match a BELL, \u0007
\A	?	
Match at the beginning of the input. Differs from ^ in that \A will not match after a new line within the input.
\b	?	
Match if the current position is a word boundary. Boundaries occur at the transitions between word (\w) and non-word (\W) characters, with combining marks ignored. For better word boundaries, see ICU Boundary Analysis .
\B	 ?	 	Match if the current position is not a word boundary.
\cX	 ?	? 	Match a control-X character.
\d	 ?	? 	Match any character with the Unicode General Category of Nd (Number, Decimal Digit.)
\D	 ?	? 	Match any character that is not a decimal digit.
\e	 ?	? 	Match an ESCAPE, \u001B.
\E	 ?	 ?	Terminates a \Q ... \E quoted sequence.
\f	 ?	? 	Match a FORM FEED, \u000C.
\G	 ?	 	Match if the current position is at the end of the previous match.
\n	 ?	? 	Match a LINE FEED, \u000A.
\N{UNICODE CHARACTER NAME}	 ?	? 	Match the named character.
\p{UNICODE PROPERTY NAME}	 ?	? 	Match any character with the specified Unicode Property.
\P{UNICODE PROPERTY NAME}	 ?	? 	Match any character not having the specified Unicode Property.
\Q	 ?	 ?	Quotes all following characters until \E.
\r	 ?	? 	Match a CARRIAGE RETURN, \u000D.
\s	 ?	?	Match a white space character. White space is defined as [\t\n\f\r\p{Z}].
\S	 ?	? 	Match a non-white space character.
\t	 ?	? 	Match a HORIZONTAL TABULATION, \u0009.
\uhhhh	 ?	? 	Match the character with the hex value hhhh.
\Uhhhhhhhh	 ?	? 	Match the character with the hex value hhhhhhhh. Exactly eight hex digits must be provided, even though the largest Unicode code point is \U0010ffff.
\w	 ?	? 	Match a word character. Word characters are [\p{Ll}\p{Lu}\p{Lt}\p{Lo}\p{Nd}].
\W	 ?	? 	Match a non-word character.
\x{hhhh}	 ?	? 	Match the character with hex value hhhh. From one to six hex digits may be supplied.
\xhh	 ?	? 	Match the character with two digit hex value hh
\X	 ?	 	Match a Grapheme Cluster .
\Z	 ?	 	Match if the current position is at the end of input, but before the final line terminator, if one exists.
\z	 ?	 	Match if the current position is at the end of input.
\n	 ?	 	Back Reference. Match whatever the nth capturing group matched. n must be a number > 1 and < total number of capture groups in the pattern.
\0ooo	 ?	? 	Match an Octal character.  'ooo' is from one to three octal digits.  0377 is the largest allowed Octal character.  The leading zero is required; it distinguishes Octal constants from back references.
[pattern]	 ?	? 	Match any one character from the set. 
.	 ?	 	Match any character.
^	 ?	 	Match at the beginning of a line.
$	 ?	 	Match at the end of a line.
\	 ?	 	Quotes the following character. Characters that must be quoted to be treated as literals are * ? + [ ( ) { } ^ $ | \ .
\	 	 ?	Quotes the following character. Characters that must be quoted to be treated as literals are [ ] \
Characters that may need to be quoted, depending on the context are - &
Regular Expression Operators

Operator	Description
|	Alternation. A|B matches either A or B.
*	Match 0 or more times. Match as many times as possible.
+	Match 1 or more times. Match as many times as possible.
?	Match zero or one times. Prefer one.
{n}	Match exactly n times
{n,}	Match at least n times. Match as many times as possible.
{n,m}	Match between n and m times. Match as many times as possible, but not more than m.
*?	Match 0 or more times. Match as few times as possible.
+?	Match 1 or more times. Match as few times as possible.
??	Match zero or one times. Prefer zero.
{n}?	Match exactly n times
{n,}?	Match at least n times, but no more than required for an overall pattern match
{n,m}?	Match between n and m times. Match as few times as possible, but not less than n.
*+	Match 0 or more times. Match as many times as possible when first encountered, do not retry with fewer even if overall match fails (Possessive Match)
++	Match 1 or more times. Possessive match.
?+	Match zero or one times. Possessive match.
{n}+	Match exactly n times
{n,}+	Match at least n times. Possessive Match.
{n,m}+	Match between n and m times. Possessive Match.
( ... )	Capturing parentheses. Range of input that matched the parenthesized subexpression is available after the match.
(?: ... )	Non-capturing parentheses. Groups the included pattern, but does not provide capturing of matching text. Somewhat more efficient than capturing parentheses.
(?> ... )	Atomic-match parentheses. First match of the parenthesized subexpression is the only one tried; if it does not lead to an overall pattern match, back up the search for a match to a position before the "(?>"
(?# ... )	Free-format comment (?# comment ).
(?= ... )	Look-ahead assertion. True if the parenthesized pattern matches at the current input position, but does not advance the input position.
(?! ... )	Negative look-ahead assertion. True if the parenthesized pattern does not match at the current input position. Does not advance the input position.
(?<= ... )	Look-behind assertion. True if the parenthesized pattern matches text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.)
(?<! ... )	Negative Look-behind assertion. True if the parenthesized pattern does not match text preceding the current input position, with the last character of the match being the input character just before the current position. Does not alter the input position. The length of possible strings matched by the look-behind pattern must not be unbounded (no * or + operators.)
(?ismwx-ismwx: ... )	Flag settings. Evaluate the parenthesized expression with the specified flags enabled or -disabled.
(?ismwx-ismwx)	Flag settings. Change the flag settings. Changes apply to the portion of the pattern following the setting. For example, (?i) changes to a case insensitive match.
Set Expressions (Character Classes)

Example	Description
[abc]	Match any of the characters a, b or c
[^abc]	Negation - match any character except a, b or c
[A-M]	Range - match any character from A to M. The characters to include are determined by Unicode code point ordering.
[\u0000-\U0010ffff]	Range - match all characters.
[\p{Letter}]
[\p{General_Category=Letter}]
[\p{L}]	Characters with Unicocde Category = Letter. All forms shown are equivalent.
[\P{Letter}]	Negated property. (Upper case \P) Match everything except Letters.
[\p{numeric_value=9}]	Match all numbers with a numeric value of 9. Any Unicode Property may be used in set expressions.
[\p{Letter}&&\p{script=cyrillic}]	Logical AND or intersection.  Match the set of all Cyrillic letters.
[\p{Letter}--\p{script=latin}] 	Subtraction.  Match all non-Latin letters.
[[a-z][A-Z][0-9]]
[a-zA-Z0-9]] 	Implicit Logical OR or Union of Sets.  The examples match ASCII letters and digits.  The two forms are equivalent.
[:script=Greek:]
 Alternate POSIX-like syntax for properties.  Equivalent to \p{script=Greek}
 	 
*/
