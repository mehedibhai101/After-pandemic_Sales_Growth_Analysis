# 📊 Calculated Columns: Maria's Kitchen Annual Sales Analysis

This documentation provides a comprehensive overview of the Calculated Tables and Calculated Columns used for the Maria's Kitchen analysis. It outlines the structural transformations and row-level logic used to drive business insights and product performance metrics.

---

### Customer Table

* **Age**: Calculates the customer's current age based on their birth date to enable time-based demographic filtering.
    * **Formula**: `DATEDIFF( 'Dim Customer'[Birth Date], TODAY(), YEAR )`
    * **Formatting**: `0`


* **Age (groups)**: Segments customers into specific age brackets for high-level demographic analysis and life-stage profiling.
    * **Formula**:
    
    
    ```dax
    SWITCH(
        TRUE,
        ISBLANK('Dim Customer'[Age]), "(Blank)",
        'Dim Customer'[Age] IN {46..55}, "46-55",
        'Dim Customer'[Age] IN {56..65}, "56-65",
        'Dim Customer'[Age] IN {66..75}, "66-75",
        'Dim Customer'[Age] IN {76..85}, "76-85",
        'Dim Customer'[Age] IN {86..95}, "86-95",
        'Dim Customer'[Age] IN {96..105}, "96-105",
        'Dim Customer'[Age] > 105, "above 105",
        "Other"
    )
    ```
    
    
    * **Formatting**: `Text`



---

### Sales Table

* **Return Amount**: Calculates the financial value of returned items by pulling the price from the Product dimension.
    * **Formula**: `RELATED( 'Dim Product'[Price] ) * 'Fact Return'[Return Quantity]`
    * **Formatting**: `General Number`


* **Cost**: Fetches the per-unit cost from the Product dimension into the Sales fact table to facilitate margin analysis.
    * **Formula**: `RELATED( 'Dim Product'[Cost] )`
    * **Formatting**: `General Number`


* **Price**: Fetches the per-unit retail price from the Product dimension into the Sales fact table.
    * **Formula**: `RELATED( 'Dim Product'[Price])`
    * **Formatting**: `General Number`


* **Total Cost**: Calculates the total expenditure for a specific sales line item.
    * **Formula**: `'Fact Sales'[Quantity] * 'Fact Sales'[Cost]`
    * **Formatting**: `General Number`


* **Sales Amount**: Calculates the gross revenue for a sales line item.
  * **Formula**: `'Fact Sales'[Price] * 'Fact Sales'[Quantity]`
  * **Formatting**: `\$#,0.00;(\$#,0.00);\$#,0.00`



---

### 💡 Data & Column Logics:

* **Data Integrity Logic**: Calculated columns like **Cost** and **Price** utilize the `RELATED` function, ensuring the fact table inherits the correct pricing metadata from the central **Dim Product** table. This maintains a "Star Schema" efficiency for secondary calculations like **Total Cost** and **Sales Amount**.
* **Age Buckets Logic**: The **Age (groups)** column uses a `SWITCH(TRUE)` pattern to create categorical buckets for every 10 years, allowing for streamlined dashboard filtering and identifying the primary customer life-stage driving revenue.
* **🔍 Revenue & Return Correlation**: By materializing the **Return Amount** using dimensional pricing, the model allows for an accurate "Net Sales" calculation that accounts for price fluctuations recorded in the Product dimension.
