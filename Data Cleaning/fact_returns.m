let
    // Extracted the returns data from the CSV source.
    Source_Data = Csv.Document(File.Contents("your_file_path.csv"),[Delimiter=",", Columns=4, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Promoted the first row to headers to identify return dates, products, and territories.
    Promote_Headers = Table.PromoteHeaders(Source_Data, [PromoteAllScalars=true]),

    // Assigned the correct data types to ensure accurate date calculations and relationship mapping.
    Set_Data_Types = Table.TransformColumnTypes(Promote_Headers,{{"ReturnDate", type date}, {"ProductKey", Int64.Type}, {"TerritoryKey", Int64.Type}, {"ReturnQuantity", Int64.Type}}),

    // Renamed columns to follow a clean, professional naming convention for reporting.
    Renamed_Columns = Table.RenameColumns(Set_Data_Types,{
        {"ReturnDate", "Return Date"}, 
        {"ProductKey", "Product Key"}, 
        {"TerritoryKey", "Territory Key"}, 
        {"ReturnQuantity", "Return Quantity"}
    })
in
    Renamed_Columns
