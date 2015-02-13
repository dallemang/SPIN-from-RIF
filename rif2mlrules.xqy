declare default element namespace "http://www.w3.org/2007/rif#";

declare function local:unframe ($f)
{ fn:string-join((
                  for $x in $f/object/(Var|Const) return local:parseatom($x) ,
		  for $x in $f/slot/(Var|Const) return local:parseatom($x),
		  ' .&#xa;' ), " ") };


declare function local:parsecall ($f as node())
{
  let $fun := data($f//content/Atom/op)
  let $args := for $x in $f//content/Atom/args/(Var|Const) return local:parseatom($x)
    (: Switch on supported functions here  :)
 
  return
    if ($fun = "NEQ") then fn:concat ("filter(", $args[1], " != ", $args[2], ")", " .&#xa;")      (: NEQ is not equal :)
    else if ($fun = "NEQ") then fn:concat ("filter(", $args[1], " = ", $args[2], ")", " .&#xa;")  (: EQ is equal :)
    else ()                                                                                       (: That's all :)
};

declare function local:parseatom ($a as item())
{
  if (fn:name($a) = "Var") then fn:concat ("?", xs:string ($a))
  else if ($a/@type = "http://www.w3.org/2007/rif#iri") then fn:concat ("<", xs:string ($a), ">")
  else if (fn:matches (xs:string($a/@type), "http...www.w3.org.2001.XMLSchema", "i"))
  then fn:concat ("""", data($a), """^^xs:", fn:substring-after(data($a/@type), "#"))
  else ()
};


let $constants := //sentence/Frame

(: No constraint support yet :)
(: let $constraints := //sentence/Forall/formula/Implies/then/Atom/op[Const="http://www.w3.org/2007/rif#error"]/../../../../../.. :)

let $rules := //sentence[Forall/formula/Implies/then/Frame]

return (
"@prefix xs: <http://www.w3.org/2001/XMLSchema#> .&#10;",

if($constants) then (
  "# Constants&#10;",
  fn:string-join (
    let $construct := string-join(for $x in $constants return local:unframe($x), "  ")
    return fn:concat (
      "rule ""constants"" construct {&#10;  ",
      $construct, "} {}&#10;"
    )
  , "&#10;")
) else (),

if($rules) then (
  "# Rules&#10;",
  fn:string-join (
    for $i at $p in $rules//Implies
    let $where := string-join( (
        for $x in $i/if//Frame return local:unframe($x),
        for $x in $i/if//formula/External return local:parsecall($x) )
      , "  ")
    let $construct := string-join(for $x in $i/then//Frame return  local:unframe($x), "  ")
    return fn:concat (
      "rule ""rule", fn:string($p), """ construct {&#10;  ",
      $construct, "} {&#10;  ", $where, "}&#10;"
    )
  , "&#10;")
) else ()

)
