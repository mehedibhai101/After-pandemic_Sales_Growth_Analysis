// ⚠ Each sales query's load was diabled after appending them together into a single fact_sales query.

let
    // Extracted the base file from the local Sales directory.
    Source_Folder = Folder.Files("your_Sales_folder_path"),

    // Filtered and accessed the specific 2020 Sales binary content.
    File_Content = Source_Folder{[#"Folder Path"="your_Sales_folder_path\",Name="file_name.csv"]}[Content],

    // Imported the CSV document with the correct encoding and column count.
    Imported_Sales_2020 = Csv.Document(File_Content,[Delimiter=",", Columns=8, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Promoted the first row to headers to identify order and key fields.
    Promote_Headers = Table.PromoteHeaders(Imported_Sales_2020, [PromoteAllScalars=true]),

    // Assigned standardized data types for dates and numeric keys to ensure model compatibility.
    Set_Data_Types = Table.TransformColumnTypes(Promote_Headers,{{"OrderDate", type date}, {"StockDate", type date}, {"OrderNumber", type text}, {"ProductKey", Int64.Type}, {"CustomerKey", Int64.Type}, {"TerritoryKey", Int64.Type}, {"OrderLineItem", Int64.Type}, {"OrderQuantity", Int64.Type}}),

    // Appended the current table with the 2021 and 2022 sales tables to create a unified fact table.
    Combine_Sales_Years = Table.Combine({Set_Data_Types, #"Sales 2021", #"Sales 2022"}),

    // Renamed columns to ensure professional and readable headers for business stakeholders.
    Renamed_Columns = Table.RenameColumns(Combine_Sales_Years,{
        {"OrderDate", "Order Date"}, 
        {"StockDate", "Stock Date"}, 
        {"OrderNumber", "Order Number"}, 
        {"ProductKey", "Product Key"}, 
        {"CustomerKey", "Customer Key"}, 
        {"TerritoryKey", "Territory Key"}, 
        {"OrderLineItem", "Line Number"}, 
        {"OrderQuantity", "Quantity"}
    })
in
    Renamed_Columns
