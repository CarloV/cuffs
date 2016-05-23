#Cuffs

[![Build Status](https://travis-ci.org/CarloV/cuffs.svg?branch=master)](https://travis-ci.org/CarloV/cuffs)

### Define your own cuffs to restrict behaviour on a javascript value

`cuffs` is a library used to force a type on your javascript value. The main idea comes from the library [type-check](http://github.com/gkz/type-check), where one can check if a javascript value is of a certain type. This library is different in that we force a type onto a certain javascript value. This means that if the javascript value doesn't cohere to the type we forced, it returns an Error, otherwise values are casted or unchanged to fit the needs of the cuffs you defined. Note that forcing is only fully functional when proxies are turned on, otherwise forcing is only done once for array-like, tuple-like and object-like statements. Functions however, are fully proxied even when proxies aren't turned on. The library also allows type casting and custom types. All together this package is really useful for testing, checking input values, or giving your code some structure.

## Install

    npm install cuffs

General usage and documentation is coming soon. For now you can look at some inspiring examples below.

## Examples
```js
//note that OO look just like a pair of handcuffs, but you can call it any way you like
var OO = require('cuffs')(); 

//straightforward usage
OO('String','wow'); 	//'wow'
OO('String',0); 		//Error

//Make a separate function to cuff a specific type
//This is espescially handy if your cuff type is pretty complex or needs to be used a lot
var cuffStringOrNumber = OO('String | Number');
cuffStringOrNumber('wow'); //'wow'
cuffStringOrNumber(1); 	// 1
cuffStringOrNumber([]);    // Error

//Cast values
OO('!Number','5'); 	// 5

//Arrays, force all elements of a single type
OO('[Number]',[1,2,3,4,5]);		// [1,2,3,4,5]
OO('[Number]',[1,'2',3,4,5]);  	// Error
OO('[!Number]',[1,'2',3,4,5]); 	// [1,2,3,4,5]

//Tuples, arrays of fixed length
OO('(String, Number)',['a',1]);  // ['a',1]
OO('(String, Number)',['a']);    // Error
OO('(String, Number)',['a',1,2]);// Error

//Object properties
OO('{foo: String, bar: Number}',{foo:'baz',bar:1});						//{foo:'baz',bar:1}
OO('{foo: String, bar: Number}',{foo:'baz'});							//Error
OO('{foo: String, bar: Maybe Number}',{foo:'baz'});						//{foo:'baz'}
OO('{foo: String, bar: Number}',{foo:'baz',bar:1,baz:false});			//Error
OO('{foo: String, bar: Number,...}',{foo:'baz',bar:1,baz:false});		//{foo:'baz',bar:1,baz:false}
OO('{foo: String, bar: Number,...Boolean}',{foo:'baz',bar:1,baz:false});	//{foo:'baz',bar:1,baz:false}
OO('{foo: String, bar: Number,...Boolean}',{foo:'baz',bar:1,baz:5});		//Error

//Typed Objects
OO('RegExp{source: String, ...}', /foo/)					// /foo/
OO('RegExp{source: String, ...}', {source: 'foo'})		// Error
OO('(Array | String){length: 5,...}', [1,2,3,4,5])		// [1,2,3,4,5]
OO('(Array | String){length: 5,...}', 'abcde')			// 'abcde'
OO('(Array | String){length: 5,...}', 12345)				// Error
OO('(Array | String){length: 5,...}', [1,2,3,4])			// Error

//Functions, if correct, this returns a function that is forced on the arguments and return value
var func = OO('(String, String) -> String',function(a,b){return a + b});
func('Hello ','World'); 	//'Hello World'
func(1,2); 			   		//Error
func('Hello');		   		//Error
func('Hello',' ','World');	//Error

//Cast the arguments of the function, so we can also input other values
var func2 = OO('(!String, !String) -> String',function(a,b){return a + b});
func2(1,2);			   //'12'

//Use ellipsis to make the arguments a bit more flexible
var func3 = OO('(Number,...String) -> Boolean',function(n){return (n == arguments.length - 1)});
func3(5,'test','this','function','with','strings'); //true
func3(0);		//true
func3(1,1);		//Error 

var func4 = OO('(Number,...String,Number) -> ',function(){});
func4(6,'test','this',7); //undefined
func4(0,5);		//undefined
func4(4);		//Error 
func4(1,2,3);	//Error 

//Multiple functions
var func5 = OO('* -> -> -> String',function(a){return function(){return function(){return a}}});
func5('test')()(); 	//'test'
func5(5)()(); 		//Error

//Force even more complex statements
var obj = OO('{foo: String -> String, bar: (!Number, !Number) -> Number}',{foo: function(a){return a + "!"},bar: function(a,b){return a + b}})
obj.foo('lol');      //lol!
obj.bar('1','2'); 	 //3
obj.foo(0);			 //Error
obj.bar('1','2','3') //Error
```

## Examples when proxies are turned on
**Note: in node.js you need to turn on the harmony_proxies flag to let this work.** <br/>
**Note: for browser usage, check out http://caniuse.com/#feat=proxy which browsers are supported**

```js
//you can turn on proxies on initialization
var OO = require('cuffs')({useProxies:true});

//or in context
var OO = require('cuffs')();
OO.useProxies(true);
//Note: If you cuffed a value before (using this OO), new creations of proxies through functions will be prevented or allowed depending on the value you give it in context.

//Force objects to stay the way they are
var obj = OO('{foo: String, bar: Number}',{foo:'baz',bar:1}); //{foo:'baz',bar:1}
obj.foo = 'works'; 	            //'works'
obj.bar = "doesn't work";       //Error
obj.foo = 12345; 		        //Error
delete obj.foo; 	            //Error
obj.baz = "doesn't work either" //Error

//Add ellipsis on objects so more variables can be added
var obj = OO('{foo: String, bar: Number, ...}',{foo:'baz',bar:1}); //{foo:'baz',bar:1}
obj.baz = "now it works"; //"now it works"
delete obj.baz; 		  //"now it works"

//Force arrays to stay the way they are
var arr = OO('[Number]',[1,2,3,4,5]);
arr.push(6);             //pushes 6 to the array
arr.push("doesn't work") //Error
arr 					 //[1,2,3,4,5,6]

//Force tuples to stay the way they are
var tup = OO('(Number,String)',[1,'some string']);
tup[1] = 'works'; 	 //'works'
tup.push("doesn't work") //Error
delete tup[1] 		 //Error
tup.length = 3 		 //Error
tup 				 //[1,'works']
```

## Examples in livescript
If you use a precompiler that supports infix operators - like livescript (which is used to build this project) - then one can use cuffs infix. This makes it look like it is a real operator!
```livescript
OO = require('cuffs')!

'[String]' `OO` <[ some array of strings ]> 	# ['some','array','of','strings']

f = '(!Number, !Number) -> Number' `OO` (+)     # Here we force a curried function to be uncurried and only accept Number-like variables 
f 1 2 			# 3
f \1 \2 		# 3
f \1 			# Error
f true false 	# 1
```

Or use it to reinforce your classes (which of course also works in javascript, but this looks more neat)
```livescript
OO = require('cuffs')!

class Dog
    (@name,@age)->
        @name |>= OO \!String
        @age  |>= OO \!Number 

    set-name: '!String ->' `OO` !-> @name = it
    get-name: '-> String' `OO` -> @name

    set-age: OO do
        '!Number ->'
        !-> @age = it
    get-age: OO do
        '-> Number'
        !-> @age
```

##Fast Syntax Description

### Introduction
The idea is pretty simple, we can describe a javascript type by a string containing certain symbols and words. If we then force a javascript value to act like it does in the description two things can happen.

- A new value is returned representing the forced javascript value with respect to the described type.
- An error occurs, as we can't force that type on the specific value.

In all cases the old value remains untouched, we only return a new value that will behave the way you want it to behave.

For an advanced overview of what is possible, see the test file for more examples or try to read the source.

### Literals
The most standard form of type checking is done through literals, such as `String`, `Number`, `Boolean`, `Object`, etc. Basically it comes down to letting the literal match the constructor's name (even custom constructors). There are several ways to do this, and depending on the environment you are in, some things work and some don't, so multiple backups are in place to ensure we pick it as good as possible. Basic usage is as follows:

```js
// Things that work
OO( 'String' , 'Some String' ); // 'Some String.'
OO( 'Number' , 5 );             // 5

// Things that don't work
OO( 'String' , 5);              // Error
OO( 'Number' , '5');            // Error
```

Apart from the basic literals, there are some special literals built in, which overwrite the basic usage. 
- `Integer` - Checks numbers that are integer
- `NaN` - Checks for something that is Not a Number
- `Truthy` - Checks for truthy values
- `Untruthy` - Checks for untruthy values
- `Existent` - Checks for existing values
- `Inexistent` - Checks for inexistent values
- `All` or `*` - Matches anything

Also any custom type literals you define will be treated as special literal.

If you have a literal that contains weird symbols or part of an operation then you may use the `<Literal>` syntax.

Then there are value-literals, Numbers are recognized as being numbers and strings between quotations as literal string values.

### Arrays and Tuples

We can force array-like structures by using the square brackets `[]` or parenthesis `()`, the first is used for array sequences and the latter for tuples. In between square brackets one can only put one type, this type will be used to force on any value inside the array. When you leave a square bracket empty, it is regarded as being an empty array.

```js
//Example for array sequences that work
OO( '[String]' , ["test","this","thing"]); //["test","this","thing"]
OO( '[Number]' , [1, 2, 3, 4, 5]);         //[1, 2, 3, 4, 5]

```

Note that here array sequences are length independent, this is different for tuples. Here we force an array of fixed length of types seperated by a comma.
```js
//Example for tuples that work
OO( '(String, Number, Boolean)', ["foo", 0, true] );              // ["foo", 0, true]
OO( '(Number, Number, Number, Number, Number)', [1, 2, 3, 4, 5]); // [1,2,3,4,5]
OO( '(*,*)', ["snow","man"]);                                     // ["snow","man"]
```

Tuples of length one are distinguished by putting a single comma at the end of the tuple. For example `(Number,)` would be a tuple of length 1. If we leave out the comma the parser thinks we are just looking for a `Number` instead of a tuple that contains a number. Tuples of length zero can be created in two ways, namely `[]` or `()`.

### Objects

Forcing object-like structures is also possible using curled braces `{}`. Inside the object is a comma-seperated list of `key:type` statements with the possible inclusion of an ellipsis `...`. The key being a string, and the type being anything.

```js
//Example for objects that work
OO( '{foo:String, bar:Number}', {foo: "baz", bar: 12345});
OO( '{nope:Inexistent, yep: Existent}', {yep: true});
```

#### Ellipsis
The ellipsis argument can only be used once in an object. It comes in two variants, either we use the ellipsis bare `...` or we use it with a type `...Type`. Bare usage is a synonym for `...All`, meaning that any other key will be allowed regardless of their value. When Type is given all values not represented by a key in the object-type will be forced to that Type.

```js
//Example for objects that work with ellipsis
OO( '{foo:String, bar:Number, ...}', {foo: "baz", bar: 12345, baz: "This can be anything now"});
OO( '{nope:Inexistent, yep: Existent, ...String}', {yep: true, foo: "This can only be a string now", bar: "This one as well"});
```

#### Typed Objects
We can prepend any object-type with an other type, basically a shortcut for the And-operator.

```js
//Examples of typed objects
OO( 'String{length: 3, ...}', 'abc');
OO( 'Array{length: 2, ...}', ["one", 2]); //note: this is the same type as the snowman, but then more explicit (*,*)
```

### Modifiers and Operations

#### Or
Loosen your cuffs! There is an Or-operator, denoted by `|`, so you can have a bit more freedom in cuffing a type. The examples speak for themselves.

```js
//Example of the |-operator
OO( 'String | Number', 5);              // 5
OO( 'String | Number', '5');            // '5'
OO( 'String | Number | Boolean', true); // true
```

In general, just like with binary OR, the first type to return a truthy value is returned

#### And
Stiffen your cuffs! There is an And-operator, denoted by `&`, so you can keep your type locked up tight. It is unusual to use this, but there can be several usecases in which this comes handy, certainly when having overlapping custom types.

```js
//Examples of the &-operator
OO( 'Number & Not Integer', 3.14);              // 3.14
OO( 'Number & Truthy', 123);                    // 123
OO( 'Boolean & Truthy', true);                  // true
OO( 'Array & {length: 2, ...}', ["one", 2]);    // ["one",2]
```

#### Maybe
Doubt your cuffs! There is a Maybe-modifier! But it is not that special, `Maybe Type` is a synonym for `Inexistent | Type`

#### Not
Throw away your cuffs! There is a Not-modifier!
**Note that this doesn't work nested into arrows, castings and proxies, so be cautious with this one**

### Casts

At the moment only a few simple casts are supported (as special literals), they are `!String`, `!Number`, `!Integer`, `!Boolean` and `!Date`. They receive a value and cast it, and then return a new value (if possible). One may define casts through custom types as well!

```js
//Examples of casts
OO( '!Number', '5' );   // 5
OO( '!Boolean', 12345 ); // true
OO( '!String', 12345 );  // "12345"
```

### Arrows

#### Basic Arrows `->`

The basic usage comes in a few variants. We have hushed arrows `Something Here ->`, we have arrows that are blind `-> ReturnType`, but also combinations `->` and `(Type1, Type2) -> ReturnType`. On the right of an arrow we put a return type, this can be basically anything. On the left of an arrow we put a tuple (which may contain one typed ellipsis), or a single type (if the function has one argument).

```js
//Examples of arrows
var f = OO( '-> String', function(){return "Some String"});
f(); //"Some String"

var scream = OO( '!String -> String', function(str){return str.toUpperCase() + "!!!"});
scream("hello"); // "HELLO!!!"
scream( 12345 ); // "12345!!!"

var addAsNumbers = OO( '(!Number, !Number) -> Number', function(a,b){return a + b});
addAsNumbers("12",true); // 13
addAsNumbers(12.3,45.6); // 57.9

var argumentsLength = OO( '(...) -> Number', function(){return arguments.length});
argumentsLength(1,2,3,4,5,6,7,8); // 8
argumentsLength();                // 0
argumentsLength('a','b','c');     // 3

var joinArguments = OO( '(String, ...!String) -> String' , function(separator){
    var slice$ = [].slice;
    return slice$.call(arguments, 1).join(separator);
});
joinArguments(' - ','a',2,'c');   // "a - 2 - c"
```

#### Curried Arrows `-->` and `!-->`

Curries are functions that wait for execution until all arguments are processed. This means the amount of arguments needs to be fixed, and no ellipsis can be used.
Usage for curry `-->` is the same as for normal arrows, but here we assume the cuffed value is a curried arrow. Mostly this is not the case, so one may want to cast the curry, which can be done with `!-->`.

```js
var addAsNumbers = OO( '(!Number, !Number) !--> Number', function(a,b){return a + b});
//We can still use it as we did before
addAsNumbers("12",true); // 13
addAsNumbers(12.3,45.6); // 57.9

//We can now split the function by giving it only one argument, expecting the other one later on.
var addFive = addAsNumbers(5);
addFive(10);    //15
addFive("123"); //128

//In this example we force execution before total arguments is reached. Note that this doesn't work for the previous function.
var addNumbers = OO( '(Maybe Number, Maybe Number) !--> Number', function(a,b){return (a || 0) + (b || 0)});
addNumbers(12,34);  // 46
var addTwelve = addNumbers(12);
addTwelve(34);      // 46
addTwelve();        // 12
addNumbers();       // 0
```

#### Cuffing `this`

To specify a type for `this`, one can use the `@` operator. The syntax looks like `Type @ Function`, here Function doesn't need to be an arrow, it can also be a `Function` or any other type which you know will be a function. It explains itself well through an example.

```js
function SomeClass(){
    this.foo = 'Foo';
    this.bar = 'Bar';
}

SomeClass.prototype.toString = OO(
    'SomeClass{foo:String, bar:String, ...} @ -> String', 
    function(){ 
        return this.foo + this.bar; 
    }
);

SomeClass.prototype.changeFoo = OO(
    'SomeClass{foo:String, bar:String, ...} @ String ->',
    function(foo){ 
        this.foo = foo 
    }
);

var a = new SomeClass;
a.toString();       //FooBar
a.changeFoo("Baz");
a.toString();       //BazBar

//Of course we can still change foo to a non-string, but the cuffs will not find that funny now.
a.foo = 12345;
a.toString();       //Error

//It also looks nice when you define a binary operator in SomeClass
SomeClass.prototype.add = OO(
    'SomeClass @ SomeClass -> SomeClass',
    function(otherObject){
        var returnObject = new SomeClass;
        returnObject.foo = this.foo + otherObject.foo;
        returnObject.bar = this.bar + otherObject.bar;
        return returnObject;
    }
);

var b = new SomeClass;
var c = new SomeClass;
b.add(c).toString(); //FooFooBarBar
a.add(c).toString(); //BazFooBarBar
```

### Comments

You can do one word comments with `#small-comment`, and multiline and multispace comments using the ordinary `/* some comment */` syntax. Any comment and whitespace will just get ignored by the parser, unless you use a whitespace in a custom type (which is not recommended).  

### Proxies

As seen in the examples very much above the usage of proxies doesn't affect the syntaxis. It only solidifies your cuffs.

### Custom Types

Custom types are treated like special literals. There are a few ways to define a custom type, one can use custom types as being a macro for a different type, or you can define them from stratch using your own validation. Then there are a few ways to implement these custom types into the cuffs. Here just a basic way to add custom types, for more ways or to combine custom types check out the test file or source code.

```js
var OO = require('cuffs')({customTypes:{
    //Adding custom types using other types
    Empty: '[ Inexistent ]',
    Nothing: 'Not All',
    Character: 'String{length: 1, ...}',
    Poop: '"Poop" | "poop"',

    //Adding custom types in a more elaborate way
    Wordlike: function(err,value){if (/\w+/.test(value)){return value} else {err('Not wordlike')}}

    //Adding custom types the hard way
    Foo: function(err){return function(value){if (value.toLowerCase() == "foo") {return value} else {err('Where is the foo?')}}},
    "!Foo": function(err){return function(value){if (value.toLowerCase() == "foo") {return value} else {return "Foo"}}},

    //Adding custom types an even harder way using regexes
    "/Plus(\\d+)/": function(mat){return function(err){return function(value){return value + +mat[1]}}}
}});


//Then you can use them
OO( 'Poop', "Poop" );                            //"Poop"
OO( 'Character & Wordlike', "A");                //"A"
OO( 'Foo', OO('!Foo' , "Something Random" ) );   //"Foo"
OO( 'Plus5', 3);                                 //8
```
