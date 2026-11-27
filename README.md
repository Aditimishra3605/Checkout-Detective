# 🛒 Checkout Detective — Finding the Hidden Conversion Killer

### A Product Analytics Project | SQL • DuckDB • Python • Statistical Analysis • Power BI

## 📌 Project Overview

Checkout Detective is an end-to-end Product Analytics project focused on understanding user behaviour and identifying possible problems in the e-commerce shopping journey.

In an online shopping platform, many visitors browse products, some add products to their carts, and only a smaller number eventually complete their purchases. Understanding where visitors stop progressing through this journey is important because it helps businesses identify areas where the shopping experience can be improved.

The main goal of this project is to analyse product views, add-to-cart activities, transactions, visitor behaviour, and conversion patterns to understand where the biggest gaps occur in the shopping funnel.

Instead of only creating charts and dashboards, I used SQL queries, statistical analysis, and Power BI visualisations to investigate the data, identify patterns, compare product performance, and present meaningful findings.

## 🎯 Project Objectives

The main objectives of this project are:

- To understand how visitors interact with products on an e-commerce platform.
- To analyse the journey from viewing a product to adding it to the cart and completing a transaction.
- To calculate conversion rates between different stages of the shopping funnel.
- To identify the stages where the largest drop-offs occur.
- To compare product-level performance using views, cart activities, and transactions.
- To understand visitor behaviour and identify interesting patterns.
- To create an interactive Power BI dashboard that presents the findings in a clear and understandable way.
- To suggest possible improvements based on the observations from the analysis.

## 🛠️ Tools and Technologies Used

| Tool | Purpose |
|---|---|
| SQL | Data exploration, querying, funnel analysis, and product-level analysis |
| DuckDB | Running SQL queries and analysing the dataset |
| Python | Supporting data analysis and statistical investigation |
| Pandas | Working with and preparing the dataset |
| Power BI | Creating interactive dashboards and visualising findings |
| GitHub | Project documentation and version control |

## 📂 Dataset Information

The project uses an e-commerce event dataset containing information related to visitor activities and product interactions.

The dataset was used to investigate different stages of the shopping journey, including product views, add-to-cart activities, and completed transactions.

**Original Dataset Source:** [https://www.kaggle.com/datasets/retailrocket/ecommerce-dataset]

The original dataset is approximately 92 MB. Since GitHub has file upload size restrictions, a smaller sample dataset named `events_sample.csv` is included in this repository for reference.

The sample file contains a portion of the original records and is not the complete dataset. The complete dataset can be accessed through the original source link mentioned above.

## 🔍 Project Workflow

### 1. Data Understanding and Exploration

The first step was to understand the dataset and identify the information available for analysis.

I explored the dataset structure, examined the available columns, checked the records, and understood how different user activities were represented.

This helped me understand the data before moving towards deeper analysis.

### 2. Data Preparation

After understanding the dataset, I prepared the data for further analysis.

The preparation process included checking the data structure, reviewing relevant fields, and organising the information required for the analysis.

The objective was to make the data suitable for performing SQL queries and building meaningful analytical metrics.

### 3. SQL Analysis Using DuckDB

I used DuckDB to perform SQL-based analysis on the dataset.

The SQL analysis focused on understanding product performance, user activity, and the conversion funnel.

Some of the major areas explored were:

- Total product views.
- Add-to-cart activities.
- Total transactions.
- Product-level performance.
- View-to-cart conversion rate.
- Cart-to-transaction conversion rate.
- View-to-transaction conversion rate.
- Product-level conversion comparisons.
- Identification of products with different engagement and transaction patterns.

These queries helped break down the overall shopping journey into smaller stages and made it easier to identify where conversion gaps were occurring.

### 4. Funnel Analysis

One of the main parts of this project was analysing the e-commerce conversion funnel.

The funnel was divided into three stages:

1. Product Views
2. Add to Cart
3. Transactions

I calculated the conversion rates and drop-off percentages between these stages to understand how the activity changes as visitors move through the shopping journey.

The following metrics were used:

**View-to-Cart Rate**

Add to Cart / Product Views × 100

**Cart-to-Transaction Rate**

Transactions / Add to Cart × 100

**Overall View-to-Transaction Rate**

Transactions / Product Views × 100

I also calculated the drop-off percentages between consecutive stages to identify which transition showed the largest gap.

### 5. Statistical Analysis

Statistical analysis was performed to explore the data beyond basic totals and counts.

The purpose was to understand patterns, differences, and variations in product and visitor behaviour.

This stage helped support the SQL findings and provided additional context for interpreting the results.

### 6. Power BI Dashboard Development

After completing the SQL and analytical work, I used Power BI to build an interactive dashboard.

The dashboard is divided into two main pages.

#### Page 1: Executive Overview

This page provides a high-level overview of the e-commerce performance.

It includes:

- Key performance indicator cards.
- Product views and add-to-cart metrics.
- Unique product count.
- Conversion trend over time.
- Visitor segmentation.
- Top 10 products based on views.
- Product performance comparison.
- Key analytical observations.

The purpose of this page is to provide a quick understanding of the overall platform activity and product performance.

#### Page 2: Funnel Deep Dive

This page focuses on analysing the conversion funnel in more detail.

It includes:

- Product views.
- Add-to-cart activities.
- Total transactions.
- View-to-cart conversion rate.
- Cart-to-transaction conversion rate.
- Overall view-to-transaction conversion rate.
- Funnel visualisation.
- Drop-off comparison between funnel stages.
- Product-level filtering.
- Funnel insights and possible recommendations.

The product slicer allows the analysis to be explored for different products and helps compare their conversion performance.

## 📊 Key Findings

The analysis produced several interesting observations.

### 1. Largest Drop-off Between Product Views and Add to Cart

The View-to-Cart drop-off rate was approximately **97.40%**, which was higher than the Cart-to-Transaction drop-off rate of **67.61%**.

This indicates that the largest gap in the observed aggregate activity occurs between product views and add-to-cart actions.

### 2. Conversion Rates Across Funnel Stages

The overall conversion metrics were:

- View-to-Cart Rate: **2.60%**
- Cart-to-Transaction Rate: **32.39%**
- Overall View-to-Transaction Rate: **0.84%**

These metrics show that the transition from product views to cart activities has a much lower rate than the transition from cart activities to transactions.

### 3. Differences in Product-Level Performance

Product-level analysis showed differences in conversion behaviour across products.

For example:

- Product **1879** recorded a View-to-Cart Rate of approximately **2.15%**, but no transactions were recorded in the selected data.
- Product **4616** showed 0% across the three conversion-rate metrics in the selected data.

These observations show why analysing individual products can provide additional information that may not be visible through overall platform metrics.

## 💡 Recommendations

Based on the observations, some possible areas for improvement are:

- Improve product pages by using better images and clear product descriptions.
- Make product pricing easy to understand.
- Keep Add to Cart buttons clearly visible.
- Investigate why some products receive views but do not generate transactions.
- Compare products with different conversion patterns to identify areas that may need attention.
- Continue monitoring the conversion funnel to understand whether changes improve the results.

These are possible improvement ideas based on the observed patterns. The analysis does not establish the exact reasons behind the drop-offs.

## 📈 Business and Product Analytics Value

This project helped demonstrate how product and user activity data can be used to understand the shopping experience.

The analysis focuses not only on how many products were viewed or purchased, but also on how activity changes between different stages of the customer journey.

The SQL analysis helped identify patterns in the data, while the Power BI dashboard made those patterns easier to understand through visualisations and interactive filters.

The findings can help identify areas that may require further investigation and can support data-driven product improvement discussions.

## 📁 Repository Structure

```text
Checkout-Detective/
│
├── data/
│   └── events_sample.csv
│
├── sql/
│   └── SQL analysis files
│
├── analysis/
│   └── Statistical analysis files
│
├── dashboard/
│   ├── Checkout_Detective.pbix
│   ├── executive_overview.png
│   └── funnel_deep_dive.png
│
└── README.md
```

## 🚀 How to Explore This Project

1. Clone or download this GitHub repository.
2. Explore the sample dataset available in the `data` folder.
3. Check the SQL files to understand the queries used for analysing the e-commerce data.
4. Explore the statistical analysis files, if available.
5. Open the Power BI file to explore the dashboard and its visualisations.
6. Refer to the original dataset source if you want to access the complete dataset.

**Note:** The sample dataset may produce different results from the complete dataset because it contains only a portion of the original records. The Power BI file and documented findings should be interpreted in the context of the data used during the original analysis.

## 📚 What I Learned

Through this project, I gained practical experience in:

- Working with a large e-commerce event dataset.
- Exploring and understanding structured data.
- Writing SQL queries using DuckDB.
- Analysing product performance and visitor behaviour.
- Calculating funnel conversion and drop-off metrics.
- Performing statistical analysis.
- Creating interactive dashboards using Power BI.
- Converting analytical findings into understandable observations and recommendations.
- Understanding how data analysis can support product improvement decisions.

## 🔮 Future Improvements

Some possible future improvements for this project include:

- Building a more detailed user-level conversion funnel.
- Investigating possible reasons behind checkout abandonment.
- Performing deeper segmentation based on visitor and product characteristics.
- Tracking product performance over different time periods.
- Adding further statistical testing to investigate differences in conversion behaviour.
- Exploring product analytics tools such as Mixpanel or Amplitude.

## 👩‍💻 Author

**Aditi Mishra**

B.Tech Student | Data Science and Analytics

Interested in Data Analytics, Product Analytics, SQL, Python, and Business Intelligence.

---

⭐ If you find this project interesting, feel free to explore the repository and share your feedback.
