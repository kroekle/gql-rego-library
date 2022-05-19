package global.graphql.policy

import data.dataset as schema

default graphql_document = {}

body = b {
  not input.attributes.request.http.headers.variables
  b := {"query": graphql_document}
}

body = b {
  b := {"query": graphql_document, "variables": input.attributes.request.http.headers.variables}
}

ast = a {
  req := {
    "url": "https://us-central1-new-expo.cloudfunctions.net/graphql-ast",
    "method": "POST",
    "body": body,
    "headers": {"content-type":"application/json"}
  }
  res := http.send(req)
  a := res.body
}

graphql_variables = v {
  v := input.attributes.request.http.headers.variables
}

graphql_variables = v {
  v := input.parsed_query.query
}

graphql_variables = v {
  v := input.parsed_body.variables
}

graphql_document = g {
  g := input.parsed_body.query
} 

graphql_document = g {
  not input.parsed_body.query
  g := input.attributes.request.http.body
}

graphql_document = g {
  g := input.parsed_query.query
}

check_type(type, field) {

 fields[i][refernece][field]
 fields[i][reference][__type__] == type
}

check_reference(type, field) {

 fields[_][type][field]
}

check_argument(reference, field, value) {
  arguments[_][reference][field] == value
}

schema_types = schema_interfaces | schema_objects

schema_interfaces[i] {
  [_,node] = walk(schema.definitions)
  node.kind == "InterfaceTypeDefinition"
  
  fs := {name:{"type":type, "kind": kind} | 
    node.fields[i].kind == "FieldDefinition"
    name := node.fields[i].name.value
    type := node.fields[i].type.type.name.value
    kind := node.fields[i].type.kind
    
    }
    
    i := {node.name.value: fs}
}

schema_objects[o] {
  [_,node] = walk(schema.definitions)
  node.kind == "ObjectTypeDefinition"
  
  fs := {name:{"type":type, "kind": kind} | 
    node.fields[i].kind == "FieldDefinition"
    name := node.fields[i].name.value
    type := node.fields[i].type.type.name.value
    kind := node.fields[i].type.kind
    
    }
    
    o := {node.name.value: fs}
}

schema_fields[v] {
#non list types
  [_,node] = walk(schema.definitions)
  node.kind == "FieldDefinition"
  

   v := {
     node.name.value: {
       "type": node.type.name.value
     }}
}

schema_fields[v] {
#list types
  [_,node] = walk(schema.definitions)
  node.kind == "FieldDefinition"
  

   v := {
     node.name.value: {
       "type": node.type.type.name.value
     }}
}

arguments[v] {
  [_,node] = walk(ast.definitions)
  count(node.arguments) > 0
  args := {field:value | 
    node.arguments[i].kind == "Argument"
    value := node.arguments[j].value.value
    field := node.arguments[j].name.value
    # TODO: do not ignore value.kind
    }
  v := {node.name.value: args} 
  # ast
}

fields[v] {

  [_,node] = walk(ast.definitions)
  node.name.kind == "Name"
  
  node.kind == "Field"
  sub := {name:{"__type__":get_type(node.name.value, name)} | 
    node.selectionSet.selections[i].kind == "Field"
    node.selectionSet.selections[i].name.kind == "Name"
    name := node.selectionSet.selections[i].name.value
    }
  count(sub) > 0

  # get_type("friends", "") ast
  x := json.patch(sub,  [
    {"op": "add", "path": "/__type__", "value": get_type(node.name.value, "")}
    ])
  v := {node.name.value: x}
}

get_type(object, field) = t {
# schema_fields[_]["friends"]
  f := schema_fields[_][object]
  t := schema_types[_][f.type][field].type
} else = t {
  t := schema_fields[_][object].type
}

