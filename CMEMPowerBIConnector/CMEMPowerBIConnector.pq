// This file contains your Data Connector logic
section CMEMPowerBIConnector;

[DataSource.Kind="eccencaCorporateMemory", Publish="CMEMPowerBIConnector.Publish"]
shared CMEMPowerBIConnector.Contents = Value.ReplaceType(CMEMPowerBIConnectorImpl, CMEMPowerBIConnectorType);

// Data Source Kind description
eccencaCorporateMemory = [
    Authentication = [
         UsernamePassword = [
            UsernameLabel = Extension.LoadString("UsernameLabelText"),
            PasswordLabel = Extension.LoadString("PasswordLabelText"),
            Label = Extension.LoadString("PasswordAreaLabelText")
         ]
    ]//,
    //Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
CMEMPowerBIConnector.Publish = [
    Beta = false,
    Category = "Database",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://eccenca.com/go/power-bi-connector",
    SourceImage = CMEMPowerBIConnector.Icons,
    SourceTypeImage = CMEMPowerBIConnector.Icons
];

CMEMPowerBIConnector.Icons = [
    Icon16 = { Extension.Contents("CMEMPowerBIConnector16.png"), Extension.Contents("CMEMPowerBIConnector20.png"), Extension.Contents("CMEMPowerBIConnector24.png"), Extension.Contents("CMEMPowerBIConnector32.png") },
    Icon32 = { Extension.Contents("CMEMPowerBIConnector32.png"), Extension.Contents("CMEMPowerBIConnector40.png"), Extension.Contents("CMEMPowerBIConnector48.png"), Extension.Contents("CMEMPowerBIConnector64.png") }
];

CMEMPowerBIConnectorType = type function (
    
    cmem_base_uri as (
        Uri.Type
        meta[
            Documentation.SampleValues = {},
            Documentation.FieldCaption = Extension.LoadString("cmem_base_uri_field_caption"),
            Documentation.FieldDescription = Extension.LoadString("cmem_base_uri_field_description")
        ]
    ),

    oauth_grant_type as (
        type text
        meta [
            Documentation.FieldCaption = Extension.LoadString("grant_type_uri_field_caption"),
            Documentation.AllowedValues = {"password", "client_credentials" },
            DataSource.Path = false
        ]
    ),
    
    oauth_client_id as (
        type text
        meta[
            Documentation.SampleValues = {"cmem-service-account"},
            Documentation.FieldCaption = Extension.LoadString("oauth_client_id_field_caption"),
            DataSource.Path = false
        ]
    ),
    
    optional configField as (
        type text
        meta [
                Documentation.FieldCaption = Extension.LoadString("configField_field_caption"),
                Documentation.FieldDescription = Extension.LoadString("configField_field_description"),
                Documentation.SampleValues = {},
                Formatting.IsMultiLine = true,
                Formatting.IsCode = true
            ]
    )

) as table meta [
    Documentation.Name = Extension.LoadString("documentation_name")
];

//--------------------------------------------------------------------------------//

CMEMPowerBIConnectorImpl = (cmem_base_uri as text,
                            oauth_grant_type as text,
                            oauth_client_id as text,
                            optional configField as text
                           ) as any => 
    let
        uiInput = [cmem_base_uri=cmem_base_uri, oauth_grant_type=oauth_grant_type, oauth_client_id=oauth_client_id],
        dataRecord = handleInput(uiInput, configField), // record with validated data for grant type passwort or grant type client credentials
        
        url_DP_API_Endpoint = dpApiEndpoint(
            if Record.HasFields(dataRecord, "dp_api_endpoint") then dataRecord[dp_api_endpoint] else "",
            cmem_base_uri
        ),
        oAuthTokenUri = oAuthTokenUri(
            if Record.HasFields(dataRecord, "oauth_token_uri") then dataRecord[oauth_token_uri] else "",
            cmem_base_uri
        ),

        querycatalog = GetQueriesFromCatalog(oAuthTokenUri, url_DP_API_Endpoint, dataRecord),
        navTable = GenerateNavTable(oAuthTokenUri, url_DP_API_Endpoint, dataRecord, querycatalog)
    in
        navTable;

GetQueriesFromCatalog = (OAUTH_TOKEN_URI as nullable text, url_DP_API_Endpoint as text, dataRecord as record) as table =>
    let
        body = "query=PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
                PREFIX shui: <https://vocab.eccenca.com/shui/>
                SELECT ?query ?name ?text
                WHERE {
                  GRAPH ?graph {
                    ?query a shui:SparqlQuery .
                    ?query rdfs:label ?name .
                    ?query shui:queryText ?text .
                    FILTER (CONTAINS(LCASE(?text), ""select""))
                  }
                  FILTER (?graph NOT IN (<https://vocab.eccenca.com/shacl/>))
                }", // TODO Filter parametrized queries
        
        queryCatalog = FetchResult(OAUTH_TOKEN_URI, url_DP_API_Endpoint, dataRecord, body)
    in
        queryCatalog;

shared FetchResult = (OAUTH_TOKEN_URI as nullable text, url_DP_API_Endpoint as text, dataRecord as record, body as text) as table =>
    let
        AccessTokenHeader = GetAccessToken(OAUTH_TOKEN_URI, dataRecord),

        url = url_DP_API_Endpoint & "/default/sparql",
        headers = 
            [
                #"Content-Type" = "application/x-www-form-urlencoded",
                #"Accept"= "text/csv",
                #"Authorization" = AccessTokenHeader
            ],

        CsvDoc = Csv.Document(
            Web.Contents(
                url,
                [
                    Headers = headers,
                    Content = Text.ToBinary(body),
                    ManualStatusHandling = {401}
                ]
            ),
            [Delimiter=",", QuoteStyle=QuoteStyle.Csv]
        ),
        Csv = Table.PromoteHeaders(CsvDoc)
    in
        Csv;

GenerateNavTable = (OAUTH_TOKEN_URI as nullable text, DP_API_ENDPOINT as text, dataRecord as record, querycatalog as table) as table =>
// get table in the form: {"Name", "Key", "Data", "ItemKind", "ItemName", "IsLeaf"}
    let
        recordList = ConvertQuerycatalogToRecordList(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, querycatalog, {}),
        preparedNavtable = Table.FromRecords(
            recordList,
            type table [
                Name = text,
                Data = any,
                ItemKind = text,
                ItemName = text,
                IsLeaf = logical
            ]
        ),
        navTable = Table.ToNavigationTable(preparedNavtable, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
    in
        navTable;

ConvertQuerycatalogToRecordList = (OAUTH_TOKEN_URI as nullable text, DP_API_ENDPOINT as text, dataRecord as record, inputTable as table, outputList as list) as list =>
    let
        currentOutput =
            if
                Table.IsEmpty(inputTable)
            then
                outputList
            else
                let 
                    firstRow = Table.First(inputTable),
                        
                        querytext = firstRow[text], // relevant columns of querycatalog are text and name
                        name = firstRow[name],
                        data = HandleQueryText(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, name, querytext),
                        itemKind = if hasQueryParameter(querytext) then "Function" else "Table",
                        newRecord = [
                                        Name=name,
                                        Data=data,
                                        ItemKind=itemKind,
                                        ItemName=itemKind,
                                        IsLeaf=true
                                    ],
                    
                    _outputList = outputList & {newRecord},
                    _inputTable = Table.RemoveFirstN(inputTable, 1),
                    recursiveResult = @ConvertQuerycatalogToRecordList(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, _inputTable, _outputList)
                in
                    recursiveResult
    in
        currentOutput;

HandleQueryText = (OAUTH_TOKEN_URI as nullable text, DP_API_ENDPOINT as text, dataRecord as record, queryName as text, queryText as text) as any => 
// converts parameter queries into functions and normal queries into tables
    let
        handledQueryText=
            if hasQueryParameter(queryText)
            then transformParameterQueryIntoFunction(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, queryName, queryText) // returns function
            else FetchSPARQLQueryResult(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, queryText) // returns table
    in
        handledQueryText;

shared FetchSPARQLQueryResult = (OAUTH_TOKEN_URI as nullable text, DP_API_ENDPOINT as text, dataRecord as record, queryText as text) as table =>    
    let
        tryResultRecord = try
            let
                body = "query=" & Uri.EscapeDataString(queryText) & "&timeout=600000&distinct=true",
                csv = FetchResult(OAUTH_TOKEN_URI, DP_API_ENDPOINT, dataRecord, body)
            in
                csv,
        outputTable =
            if 
                tryResultRecord[HasError]
            then
                Table.FromRecords({tryResultRecord[Error]})
            else
                tryResultRecord[Value]
    in
         outputTable;

//
// imports
//

Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

Table.ToNavigationTable = Extension.LoadFunction("ToNavigationTable.pqm");

Authentication = Extension.LoadFunction("CMEMPowerBIConnector.Authentication.pqm");
GetAccessToken = Authentication[GetAccessToken];
dpApiEndpoint = Authentication[dpApiEndpoint];
oAuthTokenUri = Authentication[oAuthTokenUri];

ParameterQueryHandler = Extension.LoadFunction("CMEMPowerBIConnector.ParameterQueryHandler.pqm");
hasQueryParameter = ParameterQueryHandler[hasQueryParameter];
transformParameterQueryIntoFunction = ParameterQueryHandler[transformParameterQueryIntoFunction];

IniFileHandler = Extension.LoadFunction("CMEMPowerBIConnector.IniFileHandler.pqm");
shared readConfigRecordFromIni = IniFileHandler[readConfigRecordFromIni]; // import for usage in ParameterQueryHandler

InterfaceInputHandler = Extension.LoadFunction("CMEMPowerBIConnector.InterfaceInputHandler.pqm");
handleInput = InterfaceInputHandler[handleInput];
