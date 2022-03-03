# gql-rego-library

This library is intended to make writing Rego (OPA) rules more easy when working with GraphQL.  It will parse the document into AST using an external service (an example can be found [here](https://github.com/kroekle/gql-to-ast).  It also expects a schema (in AST form) to be located at data.schema, this is used to change the references into types in order to make better rules.

## Necessary items to make it work
* A service that will take a POST body in the form of a GraphQL document and return AST (like: https://github.com/kroekle/gql-to-ast)
* If that service is not on localhost:3333 then ast_url needs to be overriden with the url of the service
* The AST schema (can use the previous service to transform it) needs to be stored in OPA at data.schema

## Important rules/functions

* query_types/mutation_types
   * These rules take the references from the query/mutation document and translate them to their type.  So if you want to make a rule about a property called name on a type called Character you would do something like `query_types["Character"]["name"]`
* query_reference/mutation_reference 
  * These are functions (for now) that work off of the references in the document (normally less useful).  To make a rule about a property called name on a reference name hero you would do something like `query_reference("hero", "name")`
* query_argument/mutation_argument
  * These are functions (for now) that will check equality of an argument.  This is currently working off the references and would be more useful if it was changed to work off of types.  Using it would look something like `query_argument("hero", "id", 2001)`


## Sample Useage

```js
allow {
  not restricted_field
  not restricted_row
}

restricted_field {
  not in_group(["admin"])
  query_types["Character"]["id"]
}

restricted_field {
  not in_group(["admin", "manager"])
  query_reference("friends", "name")
}

restricted_row {
  not in_group(["admin"])
  query_argument("hero", "episode", "JEDI")
}
```
