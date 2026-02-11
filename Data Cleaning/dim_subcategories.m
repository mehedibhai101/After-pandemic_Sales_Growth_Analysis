let
    // Extracted the product subcategory data from the CSV source.
    Source_Data = Csv.Document(File.Contents("your_file_path.csv"),[Delimiter=",", Columns=3, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Promoted the first row to headers for proper field identification.
    Promoted_Headers = Table.PromoteHeaders(Source_Data, [PromoteAllScalars=true]),

    // Defined the correct data types to support efficient join operations and data modeling.
    Set_Data_Types = Table.TransformColumnTypes(Promoted_Headers,{{"ProductSubcategoryKey", Int64.Type}, {"SubcategoryName", type text}, {"ProductCategoryKey", Int64.Type}}),

    // Performed a Left Outer Join with the Category lookup to enrich the subcategory data with category names.
    Merged_Category_Data = Table.NestedJoin(Set_Data_Types, {"ProductCategoryKey"}, #"AdventureWorks Product Categories Lookup", {"Product Category Key"}, "Category_Lookup", JoinKind.LeftOuter),
    // Expanded the joined table to bring in the Category Name while ensuring no redundant key columns are created.
    Expanded_Category_Name = Table.ExpandTableColumn(Merged_Category_Data, "Category_Lookup", {"Category Name"}),

    // Renamed columns to ensure clean and readable headers for business stakeholders.
    Renamed_Columns = Table.RenameColumns(Expanded_Category_Name, {
        {"ProductSubcategoryKey", "Product Subcategory Key"}, 
        {"SubcategoryName", "Subcategory Name"}, 
        {"ProductCategoryKey", "Product Category Key"}
    })
in
    Renamed_Columns
