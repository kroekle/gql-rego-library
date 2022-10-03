# GraphQL/Rego Ribrary

This library is intended to make writing Rego (OPA) rules more easy when working with GraphQL.  It will parse the document into AST using the Rego GraphQL [builtins](https://www.openpolicyagent.org/docs/latest/policy-reference/#graphql).  It also expects a schema (in a single text field) to be located at data.schema.gql, this is used to change the references into types in order to make better rules.

## Necessary items to make it work
* The schema should to be stored in OPA at data.schema.gql
    * If the schema is in a different location then instead of using imports for the library use can use rules like the following to override
    ``` js
    query_types := qt {
      qt := data.global.graphql_opa.util.query_types with data.schema.gql as data.myschema.myproperty
    }
    ...
    ```
    * A helpful sed command that will strip comments and remove newlines (this may not be a fully JSONified, so use at your own risk)
    ``` sh
      sed -e ':a' -e 'N' -e '$!ba' -e 's/\n//g' -e 's/"[^"]*"//g' <schema file>
    ```
* The GraphQL query document needs to be in one of the following locations (if not use the same trick that was shown above)
  * input.parsed_body.query
  * input.attributes.request.http.body
  * input.parsed_query.query

## Important rules

* query_types/mutation_types
   * These rules take the references from the query/mutation document and translate them to their type.  So if you want to make a rule about a property called name on a type called Character you would do something like `query_types["Character"]["name"]`
* query_fields/mutation_fields 
  * These are rules that work off of the references in the document (normally less useful).  To make a rule about a property called name on a reference name hero you would do something like `query_fields["hero"]["name"]`
* query_arguments/mutation_arguments
  * These are rules that you can use to check the equality of an argument.  This is currently working off the references not the types.  Using it would look something like `query_arguments["hero"]["episode"] == "JEDI"`


## Sample Usage

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
  query_fields["friends"]["name"]
}

restricted_row {
  not in_group(["admin"])
  query_arguments["hero"]["episode"] == "JEDI"
}
```
