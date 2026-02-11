let
    // 1. Data Ingestion: Connect to CSV and promote headers
    Source_Data = Csv.Document(File.Contents("C:\Users\perennial\OneDrive\Documents\Battle of Insights - PowerBI\Dataset\AdventureWorks Customer Lookup.csv"),[Delimiter=",", Columns=13, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Promote_Headers = Table.PromoteHeaders(Source_Data, [PromoteAllScalars=true]),

    // 2. Data_Cleaning: Remove errors, duplicates, and empty records in bulk
    Remove_Invalid_Rows = let
        Delete_Errors = Table.RemoveRowsWithErrors(Promote_Headers, {"CustomerKey"}),
        Unique_Keys = Table.Distinct(Delete_Errors, {"CustomerKey"}),
        Unique_Emails = Table.Distinct(Unique_Keys, {"EmailAddress"}),
        Filter_Blanks = Table.SelectRows(Unique_Emails, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
    in
        Filter_Blanks,

    // 3. Text_Formatting: Collapse Trim, Proper Case, and Lower Case into one step
    // This removes the need to change types back and forth just to trim
    Apply_Text_Formatting = Table.TransformColumns(Remove_Invalid_Rows, {
        {"Prefix", each Text.Proper(Text.Trim(_)), type text},
        {"FirstName", each Text.Proper(Text.Trim(_)), type text},
        {"LastName", each Text.Proper(Text.Trim(_)), type text},
        {"EmailAddress", each Text.Lower(Text.Trim(_)), type text},
        {"MaritalStatus", Text.Trim, type text},
        {"Gender", Text.Trim, type text},
        {"EducationLevel", Text.Trim, type text},
        {"Occupation", Text.Trim, type text},
        {"HomeOwner", Text.Trim, type text}
    }),

    // 4. Batch_Value_Replacements: Collapsing 9 ReplaceValue steps into a single logical step
    // Using List.Accumulate to iterate through a mapping list
    Apply_Bulk_Replacements = let
        Replacement_Map = {
            {"MaritalStatus", "M", "Married"}, {"MaritalStatus", "S", "Single"},
            {"Gender", "M", "Male"}, {"Gender", "F", "Female"},
            {"HomeOwner", "Y", "Yes"}, {"HomeOwner", "N", "No"}, {"HomeOwner", "y", "Yes"}
        }
    in
        List.Accumulate(
            Replacement_Map, 
            Apply_Text_Formatting, 
            (state, current) => Table.ReplaceValue(state, current{1}, current{2}, Replacer.ReplaceText, {current{0}})
        ),

    // 5. Final_Schema_Transform: Merge columns, rename, and set final data types
    Finalize_Customer_Table = let
        Merge_Names = Table.CombineColumns(Apply_Bulk_Replacements, {"Prefix", "FirstName", "LastName"}, Combiner.CombineTextByDelimiter(" ", QuoteStyle.None), "Full Name"),
        Remove_Email = Table.RemoveColumns(Merge_Names, {"EmailAddress"}),
        Final_Types = Table.TransformColumnTypes(Remove_Email, {
            {"CustomerKey", Int64.Type}, {"BirthDate", type date}, {"AnnualIncome", type number}, {"TotalChildren", Int64.Type}
        }),
        Rename_Columns = Table.RenameColumns(Final_Types, {
            {"CustomerKey", "Customer Key"}, {"BirthDate", "Birth Date"}, {"MaritalStatus", "Marital Status"}, 
            {"AnnualIncome", "Annual Income"}, {"TotalChildren", "Total Children"}, {"EducationLevel", "Edu Level"}, {"HomeOwner", "Home Owner"}
        })
    in
        Rename_Columns

in
    Finalize_Customer_Table
