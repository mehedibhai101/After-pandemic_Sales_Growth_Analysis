let
    // Extracted the product data from the CSV source.
    Source_Data = Csv.Document(File.Contents("C:\Users\perennial\OneDrive\Documents\Battle of Insights - PowerBI\Dataset\TurboFront Products.csv"),[Delimiter=",", Columns=11, Encoding=1252, QuoteStyle=QuoteStyle.None]),

    // Skipped the first 4 rows to remove metadata/headers and promoted the correct header row.
    Skip_Top_Rows = Table.Skip(Source_Data, 4),
    Promote_Headers = Table.PromoteHeaders(Skip_Top_Rows, [PromoteAllScalars=true]),

    // Defined initial data types for the product fields to support table joins.
    Set_Initial_Types = Table.TransformColumnTypes(Promote_Headers,{{"ProductKey", Int64.Type}, {"ProductSubcategoryKey", Int64.Type}, {"ProductSKU", type text}, {"ProductName", type text}, {"ModelName", type text}, {"ProductDescription", type text}, {"ProductColor", type text}, {"ProductSize", type text}, {"ProductStyle", type text}, {"ProductCost", type number}, {"ProductPrice", type number}}),

    // Enriched product data by merging with the Subcategory lookup table.
    Merge_Subcategory_Data = Table.NestedJoin(Set_Initial_Types, {"ProductSubcategoryKey"}, #"AdventureWorks Product Subcategories Lookup", {"Product Subcategory Key"}, "Subcategory_Lookup", JoinKind.LeftOuter),

    // Expanded Subcategory and Category details while removing redundant key columns in a single operation.
    Expand_Lookup_Details = Table.RemoveColumns(
        Table.ExpandTableColumn(Merge_Subcategory_Data, "Subcategory_Lookup", {"Subcategory Name", "Category Name"}, {"Subcategory", "Category"}),
        {"ProductSubcategoryKey", "ProductDescription", "ModelName", "ProductSKU"}
    ),

    // Collapsed 8 ReplaceValue steps into a single iterative transformation for Size and Style attributes.
    Apply_Bulk_Replacements = List.Accumulate(
        {
            {"ProductSize", "M", "Medium"}, {"ProductSize", "L", "Large"}, {"ProductSize", "S", "Small"}, {"ProductSize", "XL", "Extra Large"},
            {"ProductStyle", "M", "Men"}, {"ProductStyle", "W", "Women"}, {"ProductStyle", "U", "Universal"}, {"ProductStyle", "Universal", "Unisex"}
        }, 
        Expand_Lookup_Details, 
        (state, current) => Table.ReplaceValue(state, current{1}, current{2}, Replacer.ReplaceText, {current{0}})
    ),

    // Finalized column names to ensure professional headers for business reporting.
    Final_Schema_Cleanup = Table.RenameColumns(Apply_Bulk_Replacements, {
        {"ProductKey", "Product Key"}, {"ProductName", "Product Name"}, {"ProductPrice", "Price"}, 
        {"ProductCost", "Cost"}, {"ProductStyle", "Style"}, {"ProductSize", "Size"}, {"ProductColor", "Color"}
    })
in
    Final_Schema_Cleanup
