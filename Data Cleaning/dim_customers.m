let
    // 1. Data Ingestion: Connect to CSV and promote headers
    Source_Data = Csv.Document(File.Contents("your_file_path.csv"),[Delimiter=",", Columns=13, Encoding=1252, QuoteStyle=QuoteStyle.None]),
    Promote_Headers = Table.PromoteHeaders(Source_Data, [PromoteAllScalars=true]),

    // 2. Data_Cleaning: Initial type conversion followed by error, duplicate, and blank removal
    Initial_Cleaning = let
        Set_Initial_Types = Table.TransformColumnTypes(Promote_Headers,{{"CustomerKey", Int64.Type}, {"Prefix", type text}, {"FirstName", type text}, {"LastName", type text}, {"BirthDate", type date}, {"MaritalStatus", type text}, {"Gender", type text}, {"EmailAddress", type text}, {"AnnualIncome", Int64.Type}, {"TotalChildren", Int64.Type}, {"EducationLevel", type text}, {"Occupation", type text}, {"HomeOwner", type text}}),
        Remove_Key_Errors = Table.RemoveRowsWithErrors(Set_Initial_Types, {"CustomerKey"}),
        Unique_Customer_Key = Table.Distinct(Remove_Key_Errors, {"CustomerKey"}),
        Unique_Email = Table.Distinct(Unique_Customer_Key, {"EmailAddress"}),
        Remove_Blank_Rows = Table.SelectRows(Unique_Email, each not List.IsEmpty(List.RemoveMatchingItems(Record.FieldValues(_), {"", null})))
    in
        Remove_Blank_Rows,

    // 3. Text_Formatting: Consolidate Case transformations and Trim operations
    Apply_Text_Formatting = let
        // Apply Proper Case and Lower Case logic
        Fix_Casing = Table.TransformColumns(Initial_Cleaning,{{"Prefix", Text.Proper, type text}, {"LastName", Text.Proper, type text}, {"FirstName", Text.Proper, type text}, {"EmailAddress", Text.Lower, type text}}),
        // Switch to Text temporarily for universal Trim as per original logic
        Cast_To_Text = Table.TransformColumnTypes(Fix_Casing, {{"TotalChildren", type text}, {"AnnualIncome", type text}, {"BirthDate", type text}, {"CustomerKey", type text}}, "en-US"),
        // Perform bulk Trim on all 13 columns
        Trim_All = Table.TransformColumns(Cast_To_Text,{{"HomeOwner", Text.Trim, type text}, {"Occupation", Text.Trim, type text}, {"EducationLevel", Text.Trim, type text}, {"TotalChildren", Text.Trim, type text}, {"AnnualIncome", Text.Trim, type text}, {"EmailAddress", Text.Trim, type text}, {"Gender", Text.Trim, type text}, {"MaritalStatus", Text.Trim, type text}, {"BirthDate", Text.Trim, type text}, {"LastName", Text.Trim, type text}, {"FirstName", Text.Trim, type text}, {"Prefix", Text.Trim, type text}, {"CustomerKey", Text.Trim, type text}})
    in
        Trim_All,

    // 4. Batch_Value_Replacements: Collapsing 9 individual ReplaceValue steps into one iterative step
    Apply_Bulk_Replacements = let
        Replacement_List = {
            {"MaritalStatus", "M", "Married"}, {"MaritalStatus", "S", "Single"},
            {"Gender", "M", "Male"}, {"Gender", "Maleale", "Male"}, {"Gender", "F", "Female"}, {"Gender", "Femaleemale", "Female"},
            {"HomeOwner", "Y", "Yes"}, {"HomeOwner", "N", "No"}, {"HomeOwner", "y", "Yes"}
        },
        // Revert types to allow specific numeric replacements/merges
        Reset_Types = Table.TransformColumnTypes(Apply_Text_Formatting,{{"CustomerKey", Int64.Type}, {"BirthDate", type date}, {"AnnualIncome", type number}, {"TotalChildren", Int64.Type}})
    in
        List.Accumulate(
            Replacement_List, 
            Reset_Types, 
            (state, current) => Table.ReplaceValue(state, current{1}, current{2}, Replacer.ReplaceText, {current{0}})
        ),

    // 5. Final_Schema_Transform: Merge columns, rename, and filter nulls
    Finalize_Customer_Table = let
        Merge_Full_Name = Table.CombineColumns(Apply_Bulk_Replacements,{"Prefix", "FirstName", "LastName"},Combiner.CombineTextByDelimiter(" ", QuoteStyle.None),"Full Name"),
        Rename_Customer_Key = Table.RenameColumns(Merge_Full_Name,{{"CustomerKey", "Customer Key"}}),
        Filter_Null_Keys = Table.SelectRows(Rename_Customer_Key, each ([Customer Key] <> null)),
        Remove_Email_Column = Table.RemoveColumns(Filter_Null_Keys,{"EmailAddress"}),
        Final_Rename = Table.RenameColumns(Remove_Email_Column,{{"BirthDate", "Birth Date"}, {"MaritalStatus", "Marital Status"}, {"AnnualIncome", "Annual Income"}, {"TotalChildren", "Total Children"}, {"EducationLevel", "Edu Level"}, {"HomeOwner", "Home Owner"}})
    in
        Final_Rename

in
    Finalize_Customer_Table
