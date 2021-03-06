# 'startsWith' function for String Object
if typeof String.prototype.startsWith != 'function'
    String.prototype.startsWith = (str) -> @indexOf str == 0


WHITESPACE = /^[\s]+/
NUMBER = /^\d*\.?\d+(?:[Ee][+-]?\d+)?/
IDENTIFIER = /^[a-zA-Z][a-zA-Z0-9_]*/
CONSTANT = /^#([a-zA-Z0-9]*)/

# Pipe not included since it can be used as a "such that" operator
BALANCED_PAIRS = [
    ['TLParen', 'TRParen']
    ['TLSqBracket', 'TRSqBracket']
    ['TLCurlyBrace', 'TRCurlyBrace']
    ['TLPipe', 'TRPipe']
    ['TLDoublePipe', 'TRDoublePipe']
    ['TLVector', 'TRVector']
    ['TIntegral', 'TDifferential']
]

INVERSES = {}
LEFT_DELIMS = []
RIGHT_DELIMS = []

for [l,r] in BALANCED_PAIRS
    INVERSES[r] = l
    INVERSES[l] = r
    LEFT_DELIMS.push l
    RIGHT_DELIMS.push r

RESERVED = (str) ->
    # case-insensitive tokens
    switch str.toLowerCase()
        when 'false' then 'TConstant'
        when 'true' then 'TConstant'
        when '&int', '&integral' then 'TIntegral'
        when '&lim', '&limit' then 'TLimit'
        when '&sum' then 'TSum'
        when '&prod', '&product' then 'TProduct'
        else  switch str
            when 'infinity' then 'TConstant'

            when 'forall' then 'TQForall'
            when 'exists' then 'TQExists'
            when 'unique' then 'TQUnique'
            when '<->', 'iff' then 'TIff'
            when '->', 'onlyif', 'implies' then 'TImplies'
            when '<-', 'if', 'impliedby', 'when', 'whenever' then 'TIf'
            when 'then' then 'TThen'
            when '&&', 'and' then 'TAnd'
            when '||', 'or' then 'TOr'
            when 'xor' then 'TXor'
            when 'not' then 'TNot'
            when '~' then 'TTilde'

            when '<' then 'TLess'
            when '<=' then 'TLessEqual'
            when '===', 'equiv' then 'TEquiv'
            when '!==', '/==', 'nequiv' then 'TNotEquiv'
            when '~=', 'congruent' then 'TCongruent'
            when 'similar', 'sim' then 'TSimilar'
            when '=', '==' then 'TEqual'
            when '!=', '/=', '<>' then 'TNotEqual'
            when '::', 'as' then 'TRatioEqual'
            when 'para', 'parallel' then 'TParallel'
            when 'perp', 'perpendicular' then 'TPerpendicular'
            when '>=' then 'TGreaterEqual'
            when '>' then 'TGreater'
            when 'subset' then 'TSubset'
            when 'psubset', 'propsubset', 'propersubset' then 'TPropSubset'
            when 'superset', 'supset' then 'TSuperset'
            when 'psuperset', 'psupset', 'propsuperset', 'propsupset', 'propersuperset', 'propersupset' then 'TPropSuperset'
            when 'in' then 'TIn'
            when '|' then 'TPipe'
            when 'divides' then 'TDivides'
            when '~|', '/|', 'ndivides', 'notdivides', 'ndivide', 'notdivide' then 'TNotDivides'

            when 'union' then 'TUnion'
            when 'intersect' then 'TIntersect'
            when '\\', 'minus' then 'TSetDiff'

            when 'choose' then 'TChoose'

            when '+' then 'TPlus'
            when '-' then 'TMinus'
            when '*' then 'TTimes'
            when '/' then 'TDivide'
            when '&/' then 'TSlash'
            when '&:' then 'TRatio'
            when 'mod', '%' then 'TModulus'
            when '^', '**' then 'TExponent'
            when '&^' then 'TSuperscript'
            when '&_' then 'TSubscript'
            when '!' then 'TBang'
            when '\'' then 'TPrime'
            when '.' then 'TDotDiff'
            when '@' then 'TCompose'
            when '@@' then 'TSelfCompose'

            when '&Re' then 'TReal'
            when '&Im' then 'TImaginary'
            when '&pd' then 'TPartial'
            when '/&pd' then 'TDivPartial'
            when '&d' then 'TDifferential'
            when '/&d' then 'TDivDiff'
            when '&D' then 'TChangeDelta'
            when '&del', '&grad' then 'TGradient'
            when '&del.', '&div' then 'TDivergence'
            when '&delx', '&curl' then 'TCurl'
            when '&x' then 'TCross'
            when '&.' then 'TDot'
            when '&w' then 'TWedge'
            when '&ox' then 'TTensor'
            when '&o+' then 'TDirectSum'
            when '&*' then 'TCartesianProduct'
            when '&v' then 'TVectorizer'
            when '&u' then 'TUnitVectorizer'
            when '&pm', '+/-' then 'TPlusMinus'
            when '&mp', '-/+' then 'TMinusPlus'
            when '&Union' then 'TBigUnion'
            when '&Intersect' then 'TBigIntersect'


            when '(' then 'TLParen'
            when ')' then 'TRParen'
            when '{' then 'TLCurlyBrace'
            when '}' then 'TRCurlyBrace'
            when '[' then 'TLSqBracket'
            when ']' then 'TRSqBracket'
            when '[:' then 'TLRangeInclusive'
            when ':]' then 'TRRangeInclusive'
            when '(:' then 'TLRangeExclusive'
            when ':)' then 'TRRangeExclusive'
            when '|:' then 'TLPipe'
            when ':|' then 'TRPipe'
            when '||:' then 'TLDoublePipe'
            when ':||' then 'TRDoublePipe'
            when '<:' then 'TLVector'
            when ':>' then 'TRVector'
            when ':' then 'TSuchThat'
            when ';' then 'TSemicolon'
            when ',' then 'TComma'

            else false

exports.Lexer = class Lexer
    tokenize: (@str) ->
        @delims = []
        @tokens = []

        i = 0
        while @chunk = @str.slice i
            throw SyntaxError unless consumed = @spaceToken() or
                    @numLiteral() or
                    @identifierOrKeywordToken() or
                    @constantToken() or
                    @opOrSep(10) or
                    @opOrSep(9) or
                    @opOrSep(8) or
                    @opOrSep(7) or
                    @opOrSep(6) or
                    @opOrSep(5) or
                    @opOrSep(4) or
                    @opOrSep(3) or
                    @opOrSep(2) or
                    @opOrSep(1)
            i += consumed

        @token tok, "auto-ins1-#{tok}" while tok = @delims.pop()

        @tokens

    token: (tag, val) ->
        @tokens.push [tag, val]

    spaceToken: ->
        return 0 unless match = WHITESPACE.exec @chunk
        match[0].length

    numLiteral: ->
        return 0 unless match = NUMBER.exec @chunk
        number = match[0]
        tag = if /[\.e]/i.exec number then 'TFloatLit' else 'TIntLit'
        @token tag, parseFloat number
        number.length

    identifierOrKeywordToken: ->
        return 0 unless match = IDENTIFIER.exec @chunk
        ident = match[0]
        tag = if RESERVED ident then RESERVED ident else 'TIdent'
        @token tag, ident
        ident.length

    constantToken: ->
        return 0 unless match = CONSTANT.exec @chunk
        @token 'TConstant', match[1]
        match[0].length

    opOrSep: (len) ->
        op = @chunk[0...len]
        return 0 unless tag = RESERVED op

        @delims.push INVERSES[tag] if tag in LEFT_DELIMS
        @pair tag if tag in RIGHT_DELIMS

        @token tag, op
        len

    pair: (tag) ->
        if tag not in @delims
            inverse = INVERSES[tag]
            @tokens.unshift [inverse, "auto-ins2-#{inverse}"]
            @delims.unshift tag
        while tag isnt expected = @delims.pop()
            @token expected, "auto-ins3-#{expected}"
