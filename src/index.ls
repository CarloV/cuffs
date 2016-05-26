require! {'./multi-array-explorer': {MultiArrayExplorer}}
id = -> it
version = \0.0.3
#idea
#you force a type on a structure
#it gives an error whenever a structure fails (even async)
#otherwise nothing happens.
#when proxies are turned on, the structure literally stays in place
#otherwise it only stays there for functions

$typeof = (a)-> #this is needed to look behind a shimmed Proxy
    return typeof! a unless a? and a@@?
    if a@@name
        return that
    else if a@@toString?
        mat = a@@toString!match /^function\s*(\w+)\(/
        if mat and mat.length == 2
            return mat.1
    return typeof! a

shallow-copy = (obj)->
    nobj = {}
    for k,v of obj
        nobj[k] = v 
    nobj

lits =
    Integer:   (err)-> -> if $typeof(it) is \Number and Math.floor(it) is it    then it else err 'Not an Integer'
    NaN:       (err)-> -> if is-NaN it                                          then it else err 'Not a Not a Number' 
    Truthy:    (err)-> -> if !!it                                               then it else err 'Not Truthy'
    Untruthy:  (err)-> -> if !it                                                then it else err 'Not Untruthy'
    Existent:  (err)-> -> if it?                                                then it else err 'Not Existent'
    Inexistent:(err)-> -> if !it?                                               then it else err 'Not Inexistent'
    '*': (err)-> -> it
    All: (err)-> -> it

    '!Number': (err)-> -> if not is-NaN it then +it else err 'Not a !Number'
    '!String': (err)-> -> '' + it# throw new Error 'Cannot cast #it to a String'
    '!Integer': (err)-> -> if not is-NaN it then Math.round(+it) else err 'Not an !Integer'
    '!Boolean': (err)-> -> !!it
    '!Date':    (err)-> -> new Date +it || it


modifiers =
    Maybe: (a,err)-> (v)-> 
        try 
            lits.Inexistent(err)(v)
        catch 
            return a v
            
                    

    Not: (a,err)-> (v)-> #only works in sync mode
        try 
            av = a v #needs to be more async
        catch
            return v
        err 'Not Not'

Cuffs = ({custom-types = {}, use-proxies = false, on-error} = {})-> 
    modes = {}
    literals = lits
    prox = Proxy
    _up = ->
        use-proxies := it
        if use-proxies and typeof window is \undefined
            prox := require \harmony-proxy

        if use-proxies and typeof prox is \undefined
            use-proxies := false
        use-proxies


    _up use-proxies

    open-tag = (t)-> if t is \array then \[ else if t is \object then \{ else \(

    go-down = (arr,pos,u = <[ parenthesis tuple object array]>)->
        arr.down!
        arr.prop \closePos pos
        if arr.prop(\type) in u
            throw new Error "Cuffs Syntax Error - Unclosed #{open-tag arr.prop(\type)} tag"

    OOError = (str,open-pos,close-pos,message)!--> 
        throw new Error "Cuffs Error - #message - From position #open-pos to position #close-pos of #str"

    process-custom-types = (o)->
        O = {}
        for let k,v of o
            switch $typeof v
            | \String => 
                p = parse-to-function parse-to-array(v), OOError(v)
                O[k] = (err)-> p
            | \Function => 
                if v.length == 2
                    O[k] = (err)-> (w)->v err,w 
                else
                    O[k] = v 
            | \Boolean \Null =>
                O[k] = null unless v
            | _ => throw new Error "Cuffs Parse Error - Can't parse the custom type #k"
        
        O

    parse-to-array = (str)->
        modus = \normal
        a = []
        a.type = \parenthesis
        a.mode = \normal
        arr = new MultiArrayExplorer a, [0]
        L = 0
        SL = str.length
        f =(s,listen-to,mode) ->
            switch $typeof listen-to
            | \String => 
                if !s.index-of listen-to
                    if no isnt mode arr, L
                        return s.slice listen-to.length

            | \RegExp => 
                if !s.search listen-to
                    m = s.match listen-to
                    if no isnt mode arr, m , L
                        return s.slice m.0.length

            | \Array =>
                for l in listen-to
                    fr = f s,l,(mode _, l, _)
                    if fr isnt no
                        return fr

            | _ => 
                throw new Error "Cuffs Parse Error - Mode key '#{s.to-string!}' of type #{$typeof s} is not supported"
            no

        rec = (s)->
            m = modes[arr.get-inherited-parent-prop \mode]
            for [listen-to,mode] in m 
                r = f s, listen-to, mode 
                if r isnt no 
                    return r

        while str.length
            L = SL - str.length
            str |>= rec

        throw new Error "Cuffs Syntax Error - You closed too many parentheses" if arr.index.length == 0
        while arr.index.length > 1
            go-down arr, SL - 1
        arr.arr

    parse-to-function = (arr,err,poly_temp = {}, poly_delegates = [], poly_cleans = [], done)->
        e = err(arr.pos || 0, arr.close-pos || arr.pos || 0)

        unless done?
            _tot_cleans = 0
            _poly_temp = shallow-copy poly_temp
            done = !->
                _tot_cleans++
                if _tot_cleans is poly_cleans.length
                    # console.log \CLEAN, _tot_cleans, poly_cleans, _poly_temp, poly_temp
                    temp_poly_temp = shallow-copy poly_temp
                    poly_temp := shallow-copy _poly_temp
                    poly_cleans := []
                    _tot_cleans := 0
                    #for c in poly_cleans => c!
                    for d in poly_delegates
                        d temp_poly_temp, [] ,[] #the empty arrays must be defined here, so they keep being shared among all types

                    poly_delegates := []
                    
        polymf = (ltr,typ)->
            #console.log ltr,typ, poly_temp
            return that is typ if poly_temp[ltr]?
            poly_temp[ltr] = typ 
            true


        sf = (u, pt = poly_temp, pd = poly_delegates, pc = poly_cleans, dn = done)->
            switch $typeof u
            | \Array => return parse-to-function u, err, pt, pd, pc, dn
            | \Function => return u e
            | _ => return lits.Inexistent e #only Undefined will be here

        <- (x) ->
            R = x!
            ->
                poly_cleans.push arr.type
                # console.log \IN arr.type, JSON.stringify(poly_temp), JSON.stringify(_poly_temp), poly_temp is _poly_temp
                try
                    r = R ...
                catch
                    done!
                    throw e
                # console.log \OUT arr.type, JSON.stringify(poly_temp), JSON.stringify(_poly_temp), poly_temp is _poly_temp
                done!
                r

        switch arr.type 
        | \parenthesis => 
            if arr.length == 0
                return -> if $typeof it is \Array and it.length == 0 then it else e 'Not an empty Tuple'
            (v)->
                sf arr.0 <| v

        | \array =>
            prelim-check = (v)-> 
                e 'Not an Array' unless v instanceof Array #if proxy is shimmed the typeof! doesnt work properly anymore
                [sf(arr.0) .. for v]

            return prelim-check unless use-proxies
            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            target[prop] = val
                            return true
                        target[prop] = sf(arr.0) val
                        true

        | \object =>
            na = {}
            ks = []
            typed = lits\*
            ellipsis = false
            for a in arr
                if $typeof(a) is \String
                    let k = a
                        ks.push k
                        na[k] = lits.Existent
                    continue
                switch a.type
                | \property => let k = a.0, v = a.1
                    ks.push k
                    if !v?
                        na[k] = lits.Existent
                    else
                        #sv = sf v
                        na[k] = v#(o,O)-> O[k] = sv o[k]]
                | \object-type => typed = a.0
                | \ellipsis =>
                    if a.length == 0
                        ellipsis = -> id
                    else
                        ellipsis = a.0

            prelim-check = (o)->
                O = sf typed <| o 
                for k,n of na 
                    O[k] = sf n <| o[k]
                if ellipsis != false
                    for k of o when k not in ks
                        O[k] = sf ellipsis <| o[k]
                else
                    for k of o when k not in ks
                        e "Didn't expect the key #k inside the object"
                O

            return prelim-check unless use-proxies

            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        if na[prop]?
                            target[prop] = sf that <| val
                        else if ellipsis != false
                            target[prop] = sf ellipsis <| val
                        else
                            e "Key can't be inside this object"
                            #return false
                        true

                    deleteProperty: (target,prop)->
                        if na[prop]?
                            tv = sf that <| void
                            if tv?
                                target[prop] = that
                            else
                                delete target[prop]
                        else
                            delete target[prop]
                        true


        | \tuple =>
            prelim-check = (v)-> 
                e 'Not an Array' unless v instanceof Array #if proxy is shimmed the typeof! doesnt work properly anymore
                e "Tuple length doesn't match" if v.length isnt arr.length
                [sf(arr[i])(v[i]) for i til v.length]

            return prelim-check unless use-proxies
            return (o)->
                O = prelim-check o
                new prox do 
                    O 
                    set: (target, prop, val, recv)->
                        if prop is \length
                            e "Tuple length doesn't match" unless val == arr.length 
                            target[prop] = val
                            return true

                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            target[prop] = val
                            return true

                        target[prop] = sf(arr[prop])(val)
                        true

                    deleteProperty: (target,prop)->
                        if isNaN prop or +prop < 0 or (+prop)%1 isnt 0
                            delete target[prop]
                            return true
                        
                        target[prop] = sf(arr[prop])(void)
                        return true

        | \argument-tuple =>
            if arr.length == 0
                return -> if $typeof(it) is \Array and it.length == 0 then it else e 'Arguments should be an empty tuple'
            else 
                ellipsii = [a for a in arr when a? and a.type is \ellipsis]length
                if ellipsii == 0
                    return (v)-> 
                        e "Argument Tuple length doesn't match" if v.length isnt arr.length
                        [sf(arr[i])(v[i]) for i til arr.length]

                else if ellipsii == 1
                    j = 0
                    fa = []
                    la = []
                    for i til arr.length 
                        a = arr[i]
                        if a? and a.type is \ellipsis 
                            j = i 
                            break
                        fa.push a
                        
                    for i from j + 1 til arr.length
                        a = arr[i]
                        la.push a

                    if arr[j].length == 0
                        ell = lits\*
                    else
                        ell = arr[j]0

                    return (v)->
                        e "Argument tuple length doesn't match" if v.length < arr.length - 1
                        fp = [sf(fa[i])(v[i]) for i til j]
                        lp = [sf(la[i])(v[i + v.length - arr.length + j + 1]) for i til arr.length - j - 1]
                        mp = [sf(ell)(v[i]) for i from j til v.length - arr.length + j + 1]
                        fp ++ mp ++ lp

                else
                    throw new Error 'An argument tuple can only hold at most one ellipsis'

        | \arrow =>
            u = []
            if arr.0? and arr.0.type in <[ tuple parenthesis ]>
                u = arr.0
            else if arr.0?
                u = [arr.0]
            
            ret = arr.1

            base = (fun,g)->
                pd = poly_delegates
                pc = poly_cleans
                pt = poly_temp
                dn = done
                poly_delegates.push (a,b,c)!->
                    pt := a
                    pd := b 
                    pc := c 

                    _tc = 0
                    _pt = shallow-copy pt
                    dn := !->
                        _tc++
                        if _tc is pc.length
                            # console.log \CLEAN, _tc, pc, _pt, pt
                            temp_poly_temp = shallow-copy pt
                            pt := shallow-copy _pt
                            pc := []
                            _tc := 0
                            #for c in poly_cleans => c!
                            for d in pd => d temp_poly_temp, [] ,[] #the empty arrays must be defined here, so they keep being shared among all types
                            pd := []
                (...b)->
                    pc.push "function"
                    try
                        b |>= sf g, pt, pd, pc, dn
                        r = sf ret, pt, pd, pc, dn <| fun.apply @, b
                    catch
                        dn!
                        throw e
                    dn!
                    r

            switch arr.arrow-type
            | \--> \!--> => 
                if u.length > 1
                    u.type = \tuple 
                    arity = u.length
                    _curry-helper = (params,_pd = poly_delegates, _pc = poly_cleans, _pt = poly_temp, _dn = done)->
                        (fun)-> 
                            e "Not a Function" unless $typeof(fun) is \Function
                            pd = _pd
                            pc = _pc
                            pt = _pt
                            dn = _dn
                            # console.log 'Delegate Curry',params
                            _pd.push (a,b,c)!->
                                # console.log 'Execute Delegate Curry',params
                                pt := a
                                pd := b 
                                pc := c 

                                _tc = 0
                                _pt = shallow-copy pt
                                dn := !->
                                    _tc++
                                    if _tc is pc.length
                                        # console.log \CLEAN, _tc, pc, _pt, pt
                                        tpt = shallow-copy pt
                                        pt := shallow-copy _pt
                                        pc := []
                                        _tc := 0
                                        #for c in poly_cleans => c!
                                        for d in pd => d tpt, [] ,[] #the empty arrays must be defined here, so they keep being shared among all types
                                        pd := []
                            (...args)->
                                pc.push "curry"
                                try
                                    r = do ~>
                                        if args.length is 0 #execute the curry
                                            for i til arity
                                                sf u[i], pt, pd, pc, dn <| params[i] #last check
                                            sf ret, pt, pd, pc, dn <| fun.apply @
                                        else #continue currying
                                            ps = params ++ args
                                            e 'Incorrect arity of curried arrow, received #{params.length} arguments and should be #{arity} arguments' if ps.length > arity
                                            narg = [sf(u[i],pt,pd,pc,dn)(ps[i]) for i til ps.length]
                                            if ps.length < arity    
                                                _CH = _curry-helper ps,pd,pc,pt,dn <| fun.apply @, narg.slice params.length,ps.length
                                                return ~> _CH ...
                                            else
                                                return sf ret, pt, pd, pc, dn <| fun.apply @, narg.slice params.length,ps.length
                                catch
                                    dn!
                                    throw e
                                dn!
                                r
                    if arr.arrow-type is \--> #only check arguments, but don't curry the function
                        return _curry-helper []
                    else #otherwise we do curry the function
                        return (fun)->
                            _curry-helper([])(curry$ fun)
                    break
                fallthrough
      
            | _ =>
                u.type = \argument-tuple
                return (fun)-> 
                    e "Not a Function" unless $typeof(fun) is \Function
                    base fun,u


        | \or =>
            (v)->
                oh = (e,A,B)-> ->
                    try
                        Af = A ...
                    catch {message}
                        m1 = message
                        _Af = false
                    
                    try
                        Bf = B ...
                    catch {message}
                        m2 = message
                        _Bf = false

                    if _Af == false and _Bf == false
                        throw new Error m1 + ' And ' + m2
                    else if _Af == false and _Bf != false
                        return Bf
                    else if _Bf == false and _Af != false
                        return Af 
                    else if $typeof(Af) is \Function and $typeof(Bf) is \Function
                        return oh e, Af,Bf
                    else #2 answers, then we just or them as usual
                        return Af || Bf
                
                oh e,sf(arr.0), sf(arr.1) <| v

        | \and =>
            (v)-> 
                ah = (e, A,B)-> -> B A ...
                ah e, sf(arr.0), sf(arr.1) <| v

        | \modifier =>
            if arr.length == 1
                arr.1 = lits\*
            (v)-> arr.0 sf(arr.1), e <| v
                
        | \literal =>
            throw new Error "Can't process empty literals" if !arr.0? or arr.0.length == 0
            a = arr.0
            if literals[a]?
                return (v)-> sf that <| v
            else
                for k,v of literals 
                    if /^\/([\s\S]*)\/([gimy]*)$/.exec k
                        r = new RegExp that.1, that.2
                        if that$ = r.exec a
                            vt = v that$
                            return sf if vt.length == 2 then ((err)-> (v)-> vt err,v) else vt
                return -> if $typeof(it) is a then it else e "Not a#{if a.to-lower-case! in <[a e o u i]> then 'n' else ''} #a"

        # | \property \object-type => throw new Error "The type '#{arr.type}' should be parsed inside an object"
        # | \ellipsis => throw new Error "the type 'ellipsis' should be parsed inside an object or argument tuple"
        | \this-binding =>
            return (fun)->
                h = sf arr.1 <| fun 
                (...b)-> h.apply sf(arr.0)(@), b

        | \string \number => 
            return -> if it is arr.0 then it else e "The #{arr.type} #{it} is unequal to #{arr.0}"

        | \polymorphism =>
            return (v)->
                if polymf arr.0, $typeof v
                    return v
                else
                    throw new Error "Polymorphism #{arr.type} can't match multiple types"

        | _ => throw new Error "Can't parse type #{arr.type} in this context"

    ((m,k,f)-->
        modes[m] = [] unless modes[m]?
        modes[m].push [k, f])

        .. \normal
            .. \( (arr,pos)-> arr.set [] .prop \type \parenthesis .prop \pos pos .up!
            .. \) (arr,pos)->
                do
                    go-down arr, pos + 1, <[ array object ]>
                while arr.prop(\type) not in <[ parenthesis tuple ]>
                yes
                
            .. \[ (arr,pos)-> arr.set [] .prop \type \array .prop \pos pos .up!
            .. \] (arr,pos)->
                do
                    go-down arr,pos + 1, <[ parenthesis tuple object ]>
                while arr.prop(\type) != \array
                yes

            .. \{ (arr,pos)->
                if arr.get!?
                    arr.wrap!prop \type \object .prop \mode \object .prop \pos pos .up!wrap!prop \type \object-type .right!
                else
                    arr.set [] .prop \type \object .prop \mode \object .prop \pos pos .up!
            .. \} (arr,pos)->
                do
                    go-down arr, pos + 1,<[ parenthesis tuple array ]>
                while arr.prop(\type) != \object
                yes
            .. \< (arr,pos)-> arr.set [] .prop \type \literal .prop \mode \literal .prop \pos pos .up!
            .. \, (arr, pos)->  
                while arr.parent-prop(\type) not in <[ parenthesis object tuple ]>
                    go-down arr, pos
                
                arr.parent-prop \type \tuple if arr.parent-prop(\type) is \parenthesis
                arr.right!
            .. \@ (arr,pos)-> #poop & lol @ haha -> wow     --->     poop & (lol @ (haha -> wow))
                arr.wrap!prop \type \this-binding .prop \pos pos .up!right!

            .. /(?:\!?\-)?\->/ (arr,mat,pos)->
                while arr.parent-prop(\type) in <[ modifier and or ]>
                    go-down arr, pos
                arr.wrap!prop \type \arrow  .prop \arrowType mat.0 .prop \pos pos .up!right!
            .. \| (arr,pos)->
                while arr.parent-prop(\type) is \modifier
                    go-down arr, pos
                arr.wrap!prop \type \or .prop \pos pos .up!right!
            .. \& (arr,pos)-> 
                while arr.parent-prop(\type) is \modifier
                    go-down arr, pos
                arr.wrap!prop \type \and .prop \pos pos .up!right!
            .. \" (arr,pos)-> arr.set [] .prop \type \string .prop \mode \string .prop \stringType \" .prop \pos pos .up!
            .. \' (arr,pos)-> arr.set [] .prop \type \string .prop \mode \string .prop \stringType \' .prop \pos pos .up!
            .. /\d+(?:\,\d+)?|\-?Infinity/ (arr,mat,pos)-> arr.set [+mat.0] .prop \type \number .prop \pos pos .prop \closePos pos + mat.0.length
            .. \... (arr,pos)-> arr.set [] .prop \type \ellipsis .prop \pos pos .up!
            .. /[a-z]\b/ (arr,mat,pos)-> arr.set [mat.0] .prop \type \polymorphism .prop \pos pos .prop \closeProp pos + 1
            .. [k for k of modifiers] (arr,val,pos)-> arr.set [] .prop \type \modifier .prop \pos pos .up!set modifiers[val] .right!
            .. \* (arr,pos)-> arr.set [\*] .prop \type \literal .prop \pos pos .prop \closePos pos + 1
            .. /[!\?$_\w]+\b/  (arr,val,pos)-> arr.set [val.0] .prop \type \literal .prop \pos pos .prop \closePos pos + val.0.length
            .. /#\w+\b/ (arr)-> arr
            .. /\/\*[\w\"!\?$_\'\s\r\n\*]*\*\// (arr)-> arr
            .. /[\s\S]/ (arr)->arr


        .. \object
            .. /\\(\:|\}|\,|\.\.\.)/ (arr,mat)-> arr.set <| (arr.get! || '') + mat.1
            .. \: (arr,pos)-> arr.wrap!prop \type \property .prop \mode \normal .prop \pos pos .up!right!
            .. \} (arr,pos)-> go-down arr, pos + 1, <[ parenthesis tuple array ]>
            .. \, (arr)-> arr.right!
            .. \... (arr,pos)-> arr.set [] .prop \type \ellipsis .prop \mode \normal .prop \pos pos .up!
            .. /[\r\n\t\s]/ (arr)->arr
            .. /[\s\S]/ (arr,mat) -> arr.set <| (arr.get! || '') + mat.0

        .. \string
            .. "\\\"" (arr)-> arr.set <| (arr.get! || '') + \"
            .. "\\'" (arr)-> arr.set <| (arr.get! || '') + \'
            .. \' (arr,pos)-> 
                if \' is arr.parent-prop \stringType 
                    go-down arr, pos + 1
                else 
                    no #ignore
            .. \" (arr,pos)-> 
                if \" is arr.parent-prop \stringType 
                    go-down arr, pos + 1
                else 
                    no #ignore
            .. /[\s\S]/ (arr,mat)-> arr.set <| (arr.get! || '') + mat.0

        .. \literal
            .. "\\>"    (arr)-> arr.set <| (arr.get! || '') + \>
            .. \>       (arr,pos)-> go-down arr, pos + 1
            .. /[\s\S]/ (arr,mat) -> arr.set <| (arr.get! || '') + mat.0

    mt = (custom-types)->
        if $typeof(custom-types) is \Array 
            for ct in custom-types
                literals := literals with process-custom-types ct 
        else
            literals := literals with process-custom-types custom-types
    
    mt custom-types

    OO = (str)->
        throw new Error "Cuffs Error - Cuffs requires the first argument to be a string" if $typeof(str) isnt \String  
        err = OOError str
        A = parse-to-array str 
        F = parse-to-function A, err
        if &length == 1
            return F
        else
            return F &1

    OO.version = version
    OO.modify-types = mt
    OO.use-proxies = _up

    OO


Cuffs.version = version
module.exports = Cuffs
