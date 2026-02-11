let
    // Load the data from CSV source with standard UTF-8 encoding
    Source_Data = Csv.Document(File.Contents("your_file_path.csv"), [Delimiter=",", Columns=4, Encoding=65001, QuoteStyle=QuoteStyle.None]),

    // Promote the first row to headers
    Promote_Headers = Table.PromoteHeaders(Source_Data, [PromoteAllScalars=true]),

    // Remove the footer row before applying type transformations
    Remove_Bottom_Rows = Table.RemoveLastN(Promote_Headers, 1),

    // Consolidate: Rename "SalesTerritoryKey" to "Territory Key" and set all Data Types in one strategic step
    Set_Schema_And_Types = Table.TransformColumnTypes(
        Table.RenameColumns(Remove_Bottom_Rows, {{"SalesTerritoryKey", "Territory Key"}}),
        {
            {"Territory Key", Int64.Type}, 
            {"Region", type text}, 
            {"Country", type text}, 
            {"Continent", type text}
        }
    )

in
    Set_Schema_And_Types
