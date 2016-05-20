#Cuffs

### Define your own cuffs to restrict behaviour on a javascript value

`cuffs` is a library used to force a type on your javascript value. The main idea comes from the library [type-check](http://github.com/gkz/type-check), where one can check if a javascript value is of a certain type. This library is different in that we force a type onto a certain javascript value. This means that if the javascript value doesn't cohere to the type we forced, it returns an Error, otherwise values are casted or unchanged to fit the needs of the cuffs you defined. Note that forcing is only fully functional when proxies are turned on, otherwise forcing is only done once for array-like, tuple-like and object-like statements. Functions however, are fully proxied even when proxies aren't turned on. The library also allows type casting and custom types. All together this package is really useful for testing, checking input values, or giving your code some solid structure.

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
OO('[Array | String]{length: 5,...}', [1,2,3,4,5])		// [1,2,3,4,5]
OO('[Array | String]{length: 5,...}', 'abcde')			// 'abcde'
OO('[Array | String]{length: 5,...}', 12345)				// Error
OO('[Array | String]{length: 5,...}', [1,2,3,4])			// Error

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
var obj = OO('{foo: String -> String, bar: (!Number, !Number) -> Number}',{foo: function(a){a + "!"},bar: function(a,b){a + b})
obj.foo(\lol); 		 //lol!
obj.bar('1','2'); 	 //3
obj.foo(0);			 //Error
obj.bar('1','2','3') //Error
```

## Examples when proxies are turned on
**Note: in node.js you need to turn on the harmony_proxies flag to let this work** <br/>
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

