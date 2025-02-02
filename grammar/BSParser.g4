parser grammar BSParser;

options { tokenVocab=BSLexer; }

@parser::header {/* parser/listener/visitor header section */}
// Appears before any #include in h + cpp files.
@parser::preinclude {/* parser precinclude section */}
// Directly preceeds the parser class declaration in the h file (e.g. for additional types etc.).
@parser::context {/* parser context section */}
// Appears in the public part of the parser in the h file.
@parser::declarations {/* private parser declarations section */}
// Appears in line with the other class member definitions in the cpp file.
@parser::definitions {/* parser definitions section */}

@parser::listenerpreinclude{}
@parser::listenerpostinclude{}
@parser::listenerdeclarations{}
@parser::listenermembers{}
@parser::listenerdefinitions{}
@parser::baselistenerpreinclude{}
@parser::baselistenerpostinclude{}
@parser::baselistenerdeclarations{}
@parser::baselistenermembers{}
@parser::baselistenerdefinitions{}
@parser::visitorpreinclude{}
@parser::visitorpostinclude{}
@parser::visitordeclarations{}
@parser::visitormembers{}
@parser::visitordefinitions{}
@parser::basevisitorpreinclude{}
@parser::basevisitorpostinclude{}
@parser::basevisitordeclarations{}
@parser::basevisitormembers{}
@parser::basevisitordefinitions{}

program
    : (globalDeclarations )+
    functions?
    INSTRUCTIONS COLON
    ( statements )*
    EOF
    ;

/******************************************
 * Header declaration information
******************************************/
globalDeclarations
    : moduleDeclaration
    | manifestDeclaration
    | stationaryDeclaration
    ;

moduleDeclaration
    : MODULE IDENTIFIER
    ;

manifestDeclaration
    : (unionType)? MANIFEST IDENTIFIER
    ;

stationaryDeclaration
    : (unionType)? STATIONARY IDENTIFIER
    ;

/******************************************
 * Function Declaration
******************************************/
functions
    : FUNCTIONS COLON
      functionDeclaration+
    ;

functionDeclaration
    : FUNCTION IDENTIFIER formalParameters ( functionTyping )? LBRACE
            ( statements )*
            returnStatement
     RBRACE
    ;

formalParameters
    : LPAREN (formalParameterList)? RPAREN
    ;

formalParameterList
    :  formalParameter (COMMA formalParameter)*
    ;

/******************************************
This has to be an identifier, because it
doesn't make sense to define: x[3] as a
parameter to a function.
******************************************/
formalParameter
    : (unionType)? IDENTIFIER
    ;

// TODO: make mat an id and repeatable
functionTyping
    : COLON unionType
    ;

// This is mandatory so that we can
// force the translation into an assignment.
returnStatement
    : RETURN primary
    | RETURN methodCall
    ;

/******************************************
 * Statements
******************************************/
blockStatement
    : LBRACE ( statements )* RBRACE
    ;

statements
    : ifStatement
    | whileStatement
    | variableDefinition
    | repeat
    | heat
    | dispose
    | mix
    | dispense
    | split
    | methodInvocation
    | gradient
    | detect
    | store
    | math
    | numberAssignment
    | send
    ;

send
    : (usein)? variableDefinition SEND (unitTracker)? IDENTIFIER TO IDENTIFIER (FOR timeIdentifier)?
    | SEND variable TO IDENTIFIER (FOR timeIdentifier)? //send a already exsisting variable to a stationary
    ;

ifStatement
    : IF parExpression blockStatement (ELSE blockStatement )?
    ;

whileStatement
    : WHILE parExpression blockStatement
    ;

repeat
    : REPEAT INTEGER_LITERAL TIMES blockStatement
    ;

heat
    :  HEAT variable AT IDENTIFIER AT temperatureIdentifier (FOR timeIdentifier)?
    |  HEAT IDENTIFIER AT temperatureIdentifier (FOR timeIdentifier)?
    ;

dispose
    : DRAIN variable
    | DISPOSE variable
    ;

mix
    :  (usein)? variableDefinition MIX (unitTracker)? variable WITH (unitTracker)? variable (ON IDENTIFIER)? (FOR timeIdentifier)?
    ;

usein
    : ATSIGN USEIN(useinType)? timeIdentifier
    ;

useinType
    : LPAREN (SLE | SEQ | SGE | FLE | FEQ | FGE) RPAREN
    ;

/********************************************************
The first one is intentionally an IDENTIFIER.  It has
to be a module, thus it cannot be indexed as an array.
********************************************************/
detect
    : variableDefinition DETECT IDENTIFIER ON variable (FOR timeIdentifier)?
    ;

split
    : variableDefinition SPLIT variable INTO INTEGER_LITERAL
    ;

/********************************************************
You can only dispense a global variable.  Thus, it has no
indexing capabilities.  Hence the identifier.
x = dispense 3 units of aaa
********************************************************/
dispense
    : variableDefinition DISPENSE (unitTracker)? IDENTIFIER
    ;

gradient
    : variableDefinition GRADIENT variable WITH variable RANGE FLOAT_LITERAL COMMA FLOAT_LITERAL AT FLOAT_LITERAL
    ;

store
    : STORE variable
    ;
/******************************************
 * Expressions
******************************************/
numberAssignment
    : variableDefinition literal
    ;

math
    : variableDefinition primary bop=(MULTIPLY | DIVIDE | '%') primary
    | variableDefinition primary bop=(ADDITION | SUBTRACT) primary
    ;

binops
    : primary (LT LT | GT GT GT | GT GT) primary
    | primary bop=(LTE | GTE | GT | LT) primary
    | primary bop=(EQUALITY | NOTEQUAL) primary
    ;

parExpression
    : LPAREN binops((AND | OR) binops)* RPAREN
    ;
/******************************************
 * Method Call
******************************************/
methodInvocation
    : variableDefinition methodCall
    ;

methodCall
    : IDENTIFIER LPAREN ( expressionList )? RPAREN
    ;

expressionList
    : primary (COMMA primary)*
    ;


/******************************************
 * Variables and Accounting
******************************************/
// If you want to inlcude an array of types:
// https://github.com/jar/grammars-v4/blob/master/java/JavaParser.g4#L582
typeType
    : primitiveType
    | chemicalType
    ;

unionType
    : LBRACKET typesList RBRACKET
    ;

typesList
    : typeType (SEMICOLON typeType)*
    ;

variableDefinition
    : (unionType)? variable ASSIGN
    ;

variable
    : IDENTIFIER(LBRACKET INTEGER_LITERAL RBRACKET)?
    ;

primary
    : literal
    | variable
    ;

literal
    : INTEGER_LITERAL
    | FLOAT_LITERAL
    | BOOL_LITERAL
    | STRING_LITERAL
    ;

primitiveType
 : BOOL
 | NAT
 | REAL
 | MAT
 ;

chemicalType
 : INTEGER_LITERAL
 | ACIDS_STRONG_NON_OXIDIZING
 | ACIDS_STRONG_OXIDIZING
 | ACIDS_CARBOXYLIC
 | ALCOHOLS_AND_POLYOLS
 | ALDEHYDES
 | AMIDES_AND_IMIDES
 | AMINES_PHOSPHINES_AND_PYRIDINES
 | AZO_DIAZO_AZIDO_HYDRAZINE_AND_AZIDE_COMPOUNDS
 | CARBAMATES
 | BASES_STRONG
 | CYANIDES_INORGANIC
 | THIOCARBAMATE_ESTERS_AND_SALTS_DITHIOCARBAMATE_ESTERS_AND_SALTS
 | ESTERS_SULFATE_ESTERS_PHOSPHATE_ESTERS_THIOPHOSPHATE_ESTERS_AND_BORATE_ESTERS
 | ETHERS
 | FLUORIDES_INORGANIC
 | HYDROCARBONS_AROMATIC
 | HALOGENATED_ORGANIC_COMPOUNDS
 | ISOCYANATES_AND_ISOTHIOCYANATES
 | KETONES
 | SULFIDES_ORGANIC
 | METALS_ALKALI_VERY_ACTIVE
 | METALS_ELEMENTAL_AND_POWDER_ACTIVE
 | METALS_LESS_REACTIVE
 | METALS_AND_METAL_COMPOUNDS_TOXIC
 | DIAZONIUM_SALTS
 | NITRILES
 | NITRO_NITROSO_NITRATE_AND_NITRITE_COMPOUNDS_ORGANIC
 | HYDROCARBONS_ALIPHATIC_UNSATURATED
 | HYDROCARBONS_ALIPHATIC_SATURATED
 | PEROXIDES_ORGANIC
 | PHENOLS_AND_CRESOLS
 | SULFONATES_PHOSPHONATES_AND_THIOPHOSPHONATES_ORGANIC
 | SULFIDES_INORGANIC
 | EPOXIDES
 | METAL_HYDRIDES_METAL_ALKYLS_METAL_ARYLS_AND_SILANES
 | ANHYDRIDES
 | SALTS_ACIDIC
 | SALTS_BASIC
 | ACYL_HALIDES_SULFONYL_HALIDES_AND_CHLOROFORMATES
 | ORGANOMETALLICS
 | OXIDIZING_AGENTS_STRONG
 | REDUCING_AGENTS_STRONG
 | NON_REDOX_ACTIVE_INORGANIC_COMPOUNDS
 | FLUORINATED_ORGANIC_COMPOUNDS
 | FLUORIDE_SALTS_SOLUBLE
 | OXIDIZING_AGENTS_WEAK
 | REDUCING_AGENTS_WEAK
 | NITRIDES_PHOSPHIDES_CARBIDES_AND_SILICIDES
 | CHLOROSILANES
 | SILOXANES
 | HALOGENATING_AGENTS
 | ACIDS_WEAK
 | BASES_WEAK
 | CARBONATE_SALTS
 | ALKYNES_WITH_ACETYLENIC_HYDROGEN
 | ALKYNES_WITH_NO_ACETYLENIC_HYDROGEN
 | CONJUGATED_DIENES
 | ARYL_HALIDES
 | AMINES_AROMATIC
 | NITRATE_AND_NITRITE_COMPOUNDS_INORGANIC
 | ACETALS_KETALS_HEMIACETALS_AND_HEMIKETALS
 | ACRYLATES_AND_ACRYLIC_ACIDS
 | PHENOLIC_SALTS
 | QUATERNARY_AMMONIUM_AND_PHOSPHONIUM_SALTS
 | SULFITE_AND_THIOSULFATE_SALTS
 | OXIMES
 | POLYMERIZABLE_COMPOUNDS
 | NOT_CHEMICALLY_REACTIVE
 | INSUFFICIENT_INFORMATION_FOR_CLASSIFICATION
 | WATER_AND_AQUEOUS_SOLUTIONS
 | NULL
 | UNKNOWN
 ;

timeIdentifier
    : TIME_NUMBER
    ;

temperatureIdentifier
    : TEMP_NUMBER
    ;

unitTracker
    :   INTEGER_LITERAL UNITS OF
    ;