// ⚠ This query's load was diabled after merging it into dim_subcategories in order to avoid snowflake schema.

let
    // Extracted the product category data from the CSV source.
    Source = Csv.Document(File.Contents("your_file_path.csv"),[Delimiter=",", Columns=2, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Promoted the first row to headers to identify Category keys and names.
    Promoted_Headers = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),

    // Assigned the correct data types to ensure proper relationship mapping in the data model.
    Set_Data_Types = Table.TransformColumnTypes(Promoted_Headers,{{"ProductCategoryKey", Int64.Type}, {"CategoryName", type text}}),

    // Renamed columns to follow a clean, professional naming convention for stakeholders.
    Renamed_Columns = Table.RenameColumns(Set_Data_Types,{{"ProductCategoryKey", "Product Category Key"}, {"CategoryName", "Category Name"}})
in
    Renamed_Columns
