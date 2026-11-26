/* conversion funnel : Out of all visitors who viewed a product, 
    how many added a product to their cart, and how many eventually made a transaction? */

WITH visitor_events AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
)
SELECT
    COUNT(*) AS total_visitors,
    SUM(viewed) AS viewed_visitors,
    SUM(added_to_cart) AS cart_visitors,
    SUM(purchased) AS purchased_visitors
FROM visitor_events;


/* SQL concept             Meaning
WITH                        Creates a temporary result called a CTE
CASE WHEN                   Checks whether a condition is true
MAX()                       Returns 1 if that visitor performed the event at least once
GROUP BY visitorid          Creates one record per visitor
SUM()                       Adds up the visitors who performed each action */




-- Conversion rates

WITH visitor_events AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
funnel AS (
    SELECT
        SUM(viewed) AS viewed_visitors,
        SUM(added_to_cart) AS cart_visitors,
        SUM(purchased) AS purchased_visitors
    FROM visitor_events
)
SELECT
    viewed_visitors,
    cart_visitors,
    purchased_visitors,
    ROUND(100.0 * cart_visitors / NULLIF(viewed_visitors, 0), 2)
        AS view_to_cart_rate,
    ROUND(100.0 * purchased_visitors / NULLIF(cart_visitors, 0), 2)
        AS cart_to_purchase_rate,
    ROUND(100.0 * purchased_visitors / NULLIF(viewed_visitors, 0), 2)
        AS view_to_purchase_rate
FROM funnel;





-- Identifying the drop-off points

WITH visitor_events AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
)
SELECT
    COUNT(*) AS total_visitors,
    SUM(CASE WHEN viewed = 1 THEN 1 ELSE 0 END) AS viewed,
    SUM(CASE
        WHEN viewed = 1 AND added_to_cart = 0
        THEN 1 ELSE 0
    END) AS viewed_but_no_cart,
    SUM(CASE
        WHEN added_to_cart = 1 AND purchased = 0
        THEN 1 ELSE 0
    END) AS cart_but_no_purchase,
    SUM(CASE
        WHEN purchased = 1
        THEN 1 ELSE 0
    END) AS purchasers
FROM visitor_events;







--Product-level analysis

/*Question: Are certain products getting lots of views but very few cart additions?
    This can help us identify products with high interest but weak purchase intent.*/

SELECT
    itemid,
    COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
    COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
    COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transaction_events,
    ROUND(
        100.0 * COUNT(CASE WHEN event = 'addtocart' THEN 1 END)
        / NULLIF(COUNT(CASE WHEN event = 'view' THEN 1 END), 0),
        2
    ) AS view_to_cart_rate
FROM events
GROUP BY itemid
HAVING COUNT(CASE WHEN event = 'view' THEN 1 END) >= 100
ORDER BY view_to_cart_rate ASC
LIMIT 20;





-- Creating a product performance table
WITH product_metrics AS (
    SELECT
        itemid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions
    FROM events
    GROUP BY itemid
)
SELECT
    itemid,
    views,
    cart_additions,
    transactions,
    ROUND(
        100.0 * cart_additions / NULLIF(views, 0),
        2
    ) AS view_to_cart_rate,
    ROUND(
        100.0 * transactions / NULLIF(views, 0),
        2
    ) AS view_to_transaction_rate
FROM product_metrics
WHERE views >= 100
ORDER BY views DESC
LIMIT 50;

/* What above query does :
Calculating views, cart additions and transaction events per product.
Calculating two conversion rates.
Filtering out products with fewer than 100 views.
Selecting the 50 most-viewed products. */





-- Finding the highest-converting products

WITH product_metrics AS (
    SELECT
        itemid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions
    FROM events
    GROUP BY itemid
)
SELECT
    itemid,
    views,
    cart_additions,
    transactions,
    ROUND(
        100.0 * cart_additions / NULLIF(views, 0),
        2
    ) AS view_to_cart_rate,
    ROUND(
        100.0 * transactions / NULLIF(views, 0),
        2
    ) AS view_to_transaction_rate
FROM product_metrics
WHERE views >= 100
ORDER BY view_to_transaction_rate DESC
LIMIT 20;
--This identifies products with the highest view-to-transaction event ratios among products with at least 100 views.






-- Finding the lowest-converting products
WITH product_metrics AS (
    SELECT
        itemid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions
    FROM events
    GROUP BY itemid
)
SELECT
    itemid,
    views,
    cart_additions,
    transactions,
    ROUND(
        100.0 * transactions / NULLIF(views, 0),
        2
    ) AS view_to_transaction_rate
FROM product_metrics
WHERE views >= 100
ORDER BY view_to_transaction_rate ASC
LIMIT 20;








-- Visitor-level product analysis

--Create visitor-product behaviour records: create one record for every unique combination of visitor and product.
WITH visitor_product AS (
    SELECT
        visitorid,
        itemid,
        MAX(CASE
            WHEN event = 'view' THEN 1
            ELSE 0
        END) AS viewed,
        MAX(CASE
            WHEN event = 'addtocart' THEN 1
            ELSE 0
        END) AS added_to_cart,
        MAX(CASE
            WHEN event = 'transaction' THEN 1
            ELSE 0
        END) AS purchased
    FROM events
    GROUP BY visitorid, itemid
)
SELECT *
FROM visitor_product
LIMIT 20;





-- Calculating product conversion using unique visitors
WITH visitor_product AS (
    SELECT
        visitorid,
        itemid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid, itemid
),
product_metrics AS (
    SELECT
        itemid,
        COUNT(DISTINCT CASE
            WHEN viewed = 1 THEN visitorid
        END) AS unique_viewers,
        COUNT(DISTINCT CASE
            WHEN viewed = 1 AND added_to_cart = 1 THEN visitorid
        END) AS viewers_who_added_to_cart,
        COUNT(DISTINCT CASE
            WHEN viewed = 1 AND purchased = 1 THEN visitorid
        END) AS viewers_who_purchased
    FROM visitor_product
    GROUP BY itemid
)
SELECT
    itemid,
    unique_viewers,
    viewers_who_added_to_cart,
    viewers_who_purchased,
    ROUND(
        100.0 * viewers_who_added_to_cart
        / NULLIF(unique_viewers, 0), 2
    ) AS visitor_view_to_cart_rate,
    ROUND(
        100.0 * viewers_who_purchased
        / NULLIF(unique_viewers, 0), 2
    ) AS visitor_view_to_purchase_rate
FROM product_metrics
WHERE unique_viewers >= 100
ORDER BY visitor_view_to_purchase_rate ASC
LIMIT 20;

/* Understanding the difference:
Earlier analysis                        Current analysis
Counts event records                    Counts unique visitors
Repeated views increase the count       Repeated views count once per visitor-product pair
Measures event ratios                   Measures visitor-product conversion   */








--Time-based behaviour and event sequencing
-- Q. Do visitors actually view a product before adding it to their cart and purchasing it?

-- understanding the timestamp:
SELECT
    timestamp,
    to_timestamp(timestamp / 1000.0) AS event_datetime,
    visitorid,
    itemid,
    event
FROM events
ORDER BY timestamp
LIMIT 20;
/*  timestamp = original timestamp in milliseconds.
    to_timestamp() = converts Unix seconds into a readable timestamp.
    ORDER BY timestamp = arranges events chronologically.*/






-- Calculating time differences between events
WITH ordered_events AS (
    SELECT
        visitorid,
        itemid,
        event,
        timestamp,
        LAG(event) OVER (
            PARTITION BY visitorid, itemid
            ORDER BY timestamp
        ) AS previous_event,
        LAG(timestamp) OVER (
            PARTITION BY visitorid, itemid
            ORDER BY timestamp
        ) AS previous_timestamp
    FROM events
)
SELECT
    visitorid,
    itemid,
    previous_event,
    event AS current_event,
    ROUND(
        (timestamp - previous_timestamp) / 60000.0,
        2
    ) AS minutes_since_previous_event
FROM ordered_events
WHERE previous_event IS NOT NULL
LIMIT 50;

/* Concept	      Meaning
LAG()	          Retrieves the previous row's value
OVER()	          Defines the window over which the function operates
PARTITION BY	  Separates data by visitor and product
ORDER BY	      Determines the event sequence
60000.0	          Converts milliseconds into minutes */









-- Measuring the time between view and add-to-cart
--Q. How long does it take visitors to add a product to their cart after viewing it?

WITH ordered_events AS (
    SELECT
        visitorid,
        itemid,
        event,
        timestamp,
        LAG(event) OVER (
            PARTITION BY visitorid, itemid
            ORDER BY timestamp
        ) AS previous_event,
        LAG(timestamp) OVER (
            PARTITION BY visitorid, itemid
            ORDER BY timestamp
        ) AS previous_timestamp
    FROM events
),
view_to_cart AS (
    SELECT
        visitorid,
        itemid,
        (timestamp - previous_timestamp) / 60000.0
            AS minutes_to_cart
    FROM ordered_events
    WHERE previous_event = 'view'
        AND event = 'addtocart'
)
SELECT
    COUNT(*) AS view_to_cart_transitions,
    ROUND(AVG(minutes_to_cart), 2) AS average_minutes,
    ROUND(MEDIAN(minutes_to_cart), 2) AS median_minutes,
    ROUND(MIN(minutes_to_cart), 2) AS minimum_minutes,
    ROUND(MAX(minutes_to_cart), 2) AS maximum_minutes
FROM view_to_cart;
/* Why calculate both average and median?
Suppose most visitors add products within 5 minutes, but one visitor takes 10 hours.
That unusually large value can distort the average. Median helps us understand the typical time more robustly.
One limitation: This measures immediately consecutive events for the same visitor-product pair.
It doesn't capture every possible view-to-cart journey if other events occurred in between. */








--Daily and hourly behaviour

-- Analyzing daily shopping activity: calculating how many views, cart additions and transaction events happened each day.
SELECT
    CAST(
        to_timestamp(timestamp / 1000.0) AS DATE
    ) AS event_date,
    COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
    COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
    COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions,
    COUNT(DISTINCT visitorid) AS unique_visitors
FROM events
GROUP BY event_date
ORDER BY event_date;

/* investigating queries :
Are there particular days with unusually high activity?
Do cart additions increase when views increase?
Are transaction events following the same pattern?
Are there days with high engagement but relatively low purchasing activity? */








-- Analyzing hourly shopping behaviour: identifing which hours have the most activity.
SELECT
    EXTRACT(
        HOUR FROM to_timestamp(timestamp / 1000.0)
    ) AS event_hour,
    COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
    COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
    COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions,
    COUNT(DISTINCT visitorid) AS unique_visitors
FROM events
GROUP BY event_hour
ORDER BY event_hour;

/* This gives us 24 possible hourly groups, from 0 to 23.
For example:
0 = midnight
9 = 9 AM
14 = 2 PM
21 = 9 PM  */








-- Calculating hourly conversion rates
-- High traffic doesn't necessarily mean high conversion. 
-- calculated the view-to-cart and view-to-transaction event ratios by hour.
SELECT
    EXTRACT(
        HOUR FROM to_timestamp(timestamp / 1000.0)
    ) AS event_hour,
    COUNT(CASE WHEN event = 'view' THEN 1 END) AS views,
    COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_additions,
    COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transactions,
    ROUND(
        100.0 * COUNT(CASE WHEN event = 'addtocart' THEN 1 END)
        / NULLIF(COUNT(CASE WHEN event = 'view' THEN 1 END), 0),
        2
    ) AS view_to_cart_rate,
    ROUND(
        100.0 * COUNT(CASE WHEN event = 'transaction' THEN 1 END)
        / NULLIF(COUNT(CASE WHEN event = 'view' THEN 1 END), 0),
        2
    ) AS view_to_transaction_rate
FROM events
GROUP BY event_hour
ORDER BY event_hour;
--These are event ratios, not visitor-level conversion rates.
--events within an hour aren't necessarily part of the same visitor journey.








--  Behavioural Segmentation.
-- Can we divide visitors into meaningful groups based on how they interact with the platform?

-- Identifying visitor segments
/* created four primary behavioural segments:
1. Segment 1 : Browsers
Visitors who viewed products but never added anything to their cart or purchased.
2. Segment 2 : Cart abandoners
Visitors who added products to their cart but never recorded a transaction.
3. Segment 3 : Purchasers
Visitors who recorded at least one transaction.
4. Segment 4 : Other activity
Visitors with cart or transaction activity but no recorded product view, according to this dataset.

I have assigned purchasers first, so the segments are mutually exclusive.
A purchaser who also viewed and added products will belong to the purchaser segment. */

-- Creating visitor segments
WITH visitor_activity AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_segments AS (
    SELECT
        visitorid,
        viewed,
        added_to_cart,
        purchased,
        CASE
            WHEN purchased = 1
                THEN 'Purchasers'
            WHEN added_to_cart = 1 AND purchased = 0
                THEN 'Cart Abandoners'
            WHEN viewed = 1 AND added_to_cart = 0
                THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_activity
)
SELECT
    visitor_segment,
    COUNT(*) AS total_visitors
FROM visitor_segments
GROUP BY visitor_segment
ORDER BY total_visitors DESC;








-- Calculating the percentage of each segment
WITH visitor_activity AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_segments AS (
    SELECT
        visitorid,
        CASE
            WHEN purchased = 1 THEN 'Purchasers'
            WHEN added_to_cart = 1 THEN 'Cart Abandoners'
            WHEN viewed = 1 THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_activity
)
SELECT
    visitor_segment,
    COUNT(*) AS total_visitors,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS visitor_percentage
FROM visitor_segments
GROUP BY visitor_segment
ORDER BY total_visitors DESC;
/* Here, SUM(COUNT(*)) OVER() calculates the total number of visitors across all segments, 
allowing us to calculate each segment's share. */








-- Comparing engagement intensity : how frequently each segment interacts with the platform.
-- Q. Are browsers viewing just one product, or are they exploring dozens? Are cart abandoners adding multiple products?
WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS total_views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS total_cart_events,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS total_transaction_events,
        COUNT(DISTINCT itemid) AS unique_products_interacted,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_segments AS (
    SELECT
        *,
        CASE
            WHEN purchased = 1 THEN 'Purchasers'
            WHEN added_to_cart = 1 THEN 'Cart Abandoners'
            WHEN viewed = 1 THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_activity
)
SELECT
    visitor_segment,
    COUNT(*) AS visitors,
    ROUND(AVG(total_views), 2) AS avg_views_per_visitor,
    ROUND(AVG(total_cart_events), 2) AS avg_cart_events_per_visitor,
    ROUND(AVG(total_transaction_events), 2) AS avg_transaction_events_per_visitor,
    ROUND(AVG(unique_products_interacted), 2) AS avg_unique_products
FROM visitor_segments
GROUP BY visitor_segment
ORDER BY visitors DESC;









-- Comparing Behaviour Across Visitor Segments.

-- Comparing visitor engagement
-- Q. Do cart abandoners behave differently from purchasers and browsers?
/* For example:
Do cart abandoners explore more products?
Do purchasers interact with fewer or more products?
Do browsers repeatedly view the same products?
Which segment generates the most engagement? */


-- Calculating engagement metrics by segment
WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS total_views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS total_cart_events,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS total_transaction_events,
        COUNT(DISTINCT itemid) AS unique_products,
        COUNT(*) AS total_events,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_segments AS (
    SELECT
        *,
        CASE
            WHEN purchased = 1 THEN 'Purchasers'
            WHEN added_to_cart = 1 THEN 'Cart Abandoners'
            WHEN viewed = 1 THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_activity
)
SELECT
    visitor_segment,
    COUNT(*) AS visitors,
    ROUND(AVG(total_events), 2) AS avg_events_per_visitor,
    ROUND(AVG(total_views), 2) AS avg_views,
    ROUND(AVG(total_cart_events), 2) AS avg_cart_events,
    ROUND(AVG(total_transaction_events), 2) AS avg_transactions,
    ROUND(AVG(unique_products), 2) AS avg_unique_products
FROM visitor_segments
GROUP BY visitor_segment
ORDER BY visitors DESC;







-- Investigating repeated product views
-- Q. Are visitors repeatedly viewing the same product without adding it to their cart?
-- This can help us identify products that attract attention but may not convince visitors to take the next step.
WITH visitor_product AS (
    SELECT
        visitorid,
        itemid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS view_count,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS cart_count,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS transaction_count
    FROM events
    GROUP BY visitorid, itemid
),
visitor_segments AS (
    SELECT
        visitorid,
        CASE
            WHEN MAX(transaction_count) > 0 THEN 'Purchasers'
            WHEN MAX(cart_count) > 0 THEN 'Cart Abandoners'
            WHEN MAX(view_count) > 0 THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_product
    GROUP BY visitorid
)
SELECT
    s.visitor_segment,
    COUNT(*) AS visitor_product_pairs,
    COUNT(CASE WHEN p.view_count > 1 THEN 1 END)
        AS repeated_view_pairs,
    COUNT(CASE
        WHEN p.view_count > 1 AND p.cart_count = 0
        THEN 1
    END) AS repeated_views_without_cart,
    ROUND(
        100.0 * COUNT(CASE
            WHEN p.view_count > 1 AND p.cart_count = 0
            THEN 1
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS repeated_view_without_cart_percentage
FROM visitor_product p
JOIN visitor_segments s
    ON p.visitorid = s.visitorid
GROUP BY s.visitor_segment
ORDER BY repeated_view_without_cart_percentage DESC;







-- Identifying product opportunities among cart abandoners: visitors who added products to their carts but never recorded a transaction.
-- Q. Which products are most frequently associated with cart abandonment?
WITH visitor_product AS (
    SELECT
        visitorid,
        itemid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid, itemid
),
cart_abandoners AS (
    SELECT
        visitorid
    FROM visitor_product
    GROUP BY visitorid
    HAVING
        MAX(added_to_cart) = 1
        AND MAX(purchased) = 0
)
SELECT
    p.itemid,
    COUNT(DISTINCT p.visitorid) AS cart_abandoning_visitors,
    COUNT(*) AS visitor_product_pairs
FROM visitor_product p
JOIN cart_abandoners c
    ON p.visitorid = c.visitorid
WHERE p.added_to_cart = 1
  AND p.purchased = 0
GROUP BY p.itemid
HAVING COUNT(DISTINCT p.visitorid) >= 10
ORDER BY cart_abandoning_visitors DESC
LIMIT 20;
-- This identifies products associated with the largest number of cart-abandoning visitors.







-- Statistical Analysis

-- Calculating visitor activity statistics : how many events visitors typically generate.
WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(*) AS total_events,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS total_views,
        COUNT(CASE WHEN event = 'addtocart' THEN 1 END) AS total_cart_events,
        COUNT(CASE WHEN event = 'transaction' THEN 1 END) AS total_transaction_events,
        COUNT(DISTINCT itemid) AS unique_products
    FROM events
    GROUP BY visitorid
)
SELECT
    COUNT(*) AS total_visitors,
    ROUND(AVG(total_events), 2) AS avg_events,
    MEDIAN(total_events) AS median_events,
    MIN(total_events) AS minimum_events,
    MAX(total_events) AS maximum_events,
    ROUND(AVG(total_views), 2) AS avg_views,
    MEDIAN(total_views) AS median_views,
    ROUND(AVG(unique_products), 2) AS avg_unique_products,
    MEDIAN(unique_products) AS median_unique_products
FROM visitor_activity;

/* Metric          What it tells us
Mean / Average     Average activity across visitors
Median             Middle visitor's activity level
Minimum            Lowest observed value
Maximum            Highest observed value  */







-- Finding the distribution of visitor activity : dividing visitors into activity groups.
WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(*) AS total_events
    FROM events
    GROUP BY visitorid
),
visitor_groups AS (
    SELECT
        visitorid,
        total_events,
        CASE
            WHEN total_events = 1 THEN '1 Event'
            WHEN total_events BETWEEN 2 AND 5 THEN '2-5 Events'
            WHEN total_events BETWEEN 6 AND 10 THEN '6-10 Events'
            WHEN total_events BETWEEN 11 AND 20 THEN '11-20 Events'
            WHEN total_events BETWEEN 21 AND 50 THEN '21-50 Events'
            ELSE '50+ Events'
        END AS activity_group
    FROM visitor_activity
)
SELECT
    activity_group,
    COUNT(*) AS visitors,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS visitor_percentage
FROM visitor_groups
GROUP BY activity_group
ORDER BY
    CASE activity_group
        WHEN '1 Event' THEN 1
        WHEN '2-5 Events' THEN 2
        WHEN '6-10 Events' THEN 3
        WHEN '11-20 Events' THEN 4
        WHEN '21-50 Events' THEN 5
        ELSE 6
    END;
/* This helps us understand whether the platform has:
A large number of visitors who interact only once.
Many visitors who explore several products.
A smaller group of highly active visitors. */






-- Identifying unusually active visitors (outliers)
-- used the 99th percentile: The 99th percentile represents the value below which approximately 99% of observations fall.
-- identifying visitors whose activity exceeds the 99th percentile.
WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(*) AS total_events
    FROM events
    GROUP BY visitorid
),
threshold AS (
    SELECT
        QUANTILE_CONT(total_events, 0.99) AS p99_events
    FROM visitor_activity
)
SELECT
    COUNT(*) AS total_visitors,
    MAX(p99_events) AS p99_threshold,
    COUNT(CASE
        WHEN total_events > p99_events THEN 1
    END) AS highly_active_visitors,
    ROUND(
        100.0 * COUNT(CASE
            WHEN total_events > p99_events THEN 1
        END) / COUNT(*),
        2
    ) AS highly_active_visitor_percentage
FROM visitor_activity
CROSS JOIN threshold
GROUP BY p99_events;







-- Comparing segments statistically
/* comparing Browsers, Cart Abandoners and Purchasers using:
Mean activity
Median activity
75th and 90th percentile activity
This will help us understand whether the differences between segments are consistent or driven by extreme visitors. */

WITH visitor_activity AS (
    SELECT
        visitorid,
        COUNT(*) AS total_events,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_segments AS (
    SELECT
        visitorid,
        total_events,
        CASE
            WHEN purchased = 1 THEN 'Purchasers'
            WHEN added_to_cart = 1 THEN 'Cart Abandoners'
            WHEN viewed = 1 THEN 'Browsers'
            ELSE 'Other Activity'
        END AS visitor_segment
    FROM visitor_activity
)
SELECT
    visitor_segment,
    COUNT(*) AS visitors,
    ROUND(AVG(total_events), 2) AS mean_events,
    MEDIAN(total_events) AS median_events,
    QUANTILE_CONT(total_events, 0.75) AS p75_events,
    QUANTILE_CONT(total_events, 0.90) AS p90_events
FROM visitor_segments
GROUP BY visitor_segment
ORDER BY visitors DESC;









-- Correlation and relationship analysis
-- Q. Do visitors who explore more products have a higher likelihood of purchasing?

-- Preparing visitor-level metrics
/* creating one record per visitor containing:
Number of product views
Number of unique products viewed
Number of cart additions
Whether they purchased */
WITH visitor_metrics AS (
    SELECT
        visitorid,
        COUNT(CASE WHEN event = 'view' THEN 1 END) AS total_views,
        COUNT(DISTINCT CASE
            WHEN event = 'view' THEN itemid
        END) AS unique_products_viewed,
        COUNT(CASE
            WHEN event = 'addtocart' THEN 1
        END) AS total_cart_additions,
        MAX(CASE
            WHEN event = 'transaction' THEN 1
            ELSE 0
        END) AS purchased
    FROM events
    GROUP BY visitorid
)
SELECT *
FROM visitor_metrics
LIMIT 20;








-- Analysing purchase likelihood by product exploration
-- divide visitors into groups based on how many unique products they viewed.
WITH visitor_metrics AS (
    SELECT
        visitorid,
        COUNT(DISTINCT CASE
            WHEN event = 'view' THEN itemid
        END) AS unique_products_viewed,
        MAX(CASE
            WHEN event = 'transaction' THEN 1
            ELSE 0
        END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_groups AS (
    SELECT
        visitorid,
        unique_products_viewed,
        purchased,
        CASE
            WHEN unique_products_viewed = 0 THEN '0 Products'
            WHEN unique_products_viewed = 1 THEN '1 Product'
            WHEN unique_products_viewed BETWEEN 2 AND 3 THEN '2-3 Products'
            WHEN unique_products_viewed BETWEEN 4 AND 5 THEN '4-5 Products'
            WHEN unique_products_viewed BETWEEN 6 AND 10 THEN '6-10 Products'
            ELSE '10+ Products'
        END AS exploration_group
    FROM visitor_metrics
)
SELECT
    exploration_group,
    COUNT(*) AS total_visitors,
    SUM(purchased) AS purchasers,
    ROUND(
        100.0 * SUM(purchased) / COUNT(*),
        2
    ) AS purchase_rate
FROM visitor_groups
GROUP BY exploration_group
ORDER BY
    CASE exploration_group
        WHEN '0 Products' THEN 1
        WHEN '1 Product' THEN 2
        WHEN '2-3 Products' THEN 3
        WHEN '4-5 Products' THEN 4
        WHEN '6-10 Products' THEN 5
        ELSE 6
    END;







-- Calculating Pearson correlation: 
--calculating a correlation coefficient between the number of unique products viewed and the purchase indicator.
WITH visitor_metrics AS (
    SELECT
        visitorid,
        COUNT(DISTINCT CASE
            WHEN event = 'view' THEN itemid
        END) AS unique_products_viewed,
        MAX(CASE
            WHEN event = 'transaction' THEN 1
            ELSE 0
        END) AS purchased
    FROM events
    GROUP BY visitorid
)
SELECT
    ROUND(
        CORR(
            unique_products_viewed,
            purchased
        ),
        4
    ) AS exploration_purchase_correlation
FROM visitor_metrics;







-- Statistical significance
-- Q. Does an observed difference reflect a genuine difference, or could it be due to random variation?

-- Hypothesis Testing
-- Q. Do visitors who explore more products have a different purchase rate from visitors who explore fewer products?

/*  Group A — Low exploration: Visitors who viewed 1–3 unique products.
    Group B — High exploration: Visitors who viewed 4 or more unique products.
Our hypotheses:
    Null hypothesis (H₀): Both groups have the same purchase rate.
    Alternative hypothesis (H₁): The purchase rates are different.
I used a two-proportion z-test with a 5% significance level. */

WITH visitor_metrics AS (
    SELECT
        visitorid,
        COUNT(DISTINCT CASE
            WHEN event = 'view' THEN itemid
        END) AS unique_products_viewed,
        MAX(CASE
            WHEN event = 'transaction' THEN 1
            ELSE 0
        END) AS purchased
    FROM events
    GROUP BY visitorid
),
visitor_groups AS (
    SELECT
        visitorid,
        purchased,
        CASE
            WHEN unique_products_viewed BETWEEN 1 AND 3
                THEN 'Low Exploration'
            WHEN unique_products_viewed >= 4
                THEN 'High Exploration'
        END AS exploration_group
    FROM visitor_metrics
    WHERE unique_products_viewed >= 1
),
group_stats AS (
    SELECT
        exploration_group,
        COUNT(*) AS visitors,
        SUM(purchased) AS purchasers,
        AVG(purchased * 1.0) AS purchase_rate
    FROM visitor_groups
    GROUP BY exploration_group
),
comparison AS (
    SELECT
        MAX(CASE
            WHEN exploration_group = 'Low Exploration'
            THEN visitors
        END) AS n1,
        MAX(CASE
            WHEN exploration_group = 'High Exploration'
            THEN visitors
        END) AS n2,
        MAX(CASE
            WHEN exploration_group = 'Low Exploration'
            THEN purchasers
        END) AS x1,
        MAX(CASE
            WHEN exploration_group = 'High Exploration'
            THEN purchasers
        END) AS x2,
        MAX(CASE
            WHEN exploration_group = 'Low Exploration'
            THEN purchase_rate
        END) AS p1,
        MAX(CASE
            WHEN exploration_group = 'High Exploration'
            THEN purchase_rate
        END) AS p2
    FROM group_stats
),
test_values AS (
    SELECT
        *,
        (x1 + x2) * 1.0 / (n1 + n2) AS pooled_rate
    FROM comparison
),
z_test AS (
    SELECT
        *,
        (p2 - p1) / SQRT(
            pooled_rate * (1 - pooled_rate)
            * (1.0 / n1 + 1.0 / n2)
        ) AS z_statistic
    FROM test_values
)
SELECT
    n1 AS low_exploration_visitors,
    n2 AS high_exploration_visitors,
    ROUND(100 * p1, 3) AS low_exploration_purchase_rate,
    ROUND(100 * p2, 3) AS high_exploration_purchase_rate,
    ROUND(100 * (p2 - p1), 3) AS difference_percentage_points,
    ROUND(z_statistic, 4) AS z_statistic,
    ROUND(
        ERFC(ABS(z_statistic) / SQRT(2.0)),
        6
    ) AS p_value
FROM z_test;







-- Creating the clean events view

CREATE OR REPLACE VIEW cd_events_clean AS
SELECT
    CAST(visitorid AS BIGINT) AS visitor_id,
    CAST(itemid AS BIGINT) AS product_id,
    CAST(transactionid AS BIGINT) AS transaction_id,
    LOWER(TRIM(event)) AS event_type,
    "timestamp" AS event_timestamp_ms,
    TO_TIMESTAMP("timestamp" / 1000.0) AS event_datetime,
    CAST(
        TO_TIMESTAMP("timestamp" / 1000.0)
        AS DATE
    ) AS event_date,
    EXTRACT(
        HOUR FROM TO_TIMESTAMP("timestamp" / 1000.0)
    ) AS event_hour
FROM events
WHERE
    visitorid IS NOT NULL
    AND itemid IS NOT NULL
    AND event IS NOT NULL
    AND "timestamp" IS NOT NULL;


-- Validating the new view
SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT visitor_id) AS unique_visitors,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    MIN(event_datetime) AS first_event,
    MAX(event_datetime) AS last_event
FROM cd_events_clean;



-- Checking event distribution
SELECT
    event_type,
    COUNT(*) AS total_events,
    COUNT(DISTINCT visitor_id) AS unique_visitors,
    COUNT(DISTINCT product_id) AS unique_products
FROM cd_events_clean
GROUP BY event_type
ORDER BY total_events DESC;





-- Building Product Analytics Data Marts

-- 1. Visitor Behaviour Mart
-- Q. What different types of users are interacting with our e-commerce platform, and how do their behaviours differ?

CREATE OR REPLACE VIEW mart_visitor_behavior AS
WITH visitor_activity AS (
    SELECT
        visitor_id,
        COUNT(*) FILTER (
            WHERE event_type = 'view'
        ) AS total_views,
        COUNT(*) FILTER (
            WHERE event_type = 'addtocart'
        ) AS total_add_to_cart,
        COUNT(*) FILTER (
            WHERE event_type = 'transaction'
        ) AS total_transactions,
        COUNT(DISTINCT product_id) FILTER (
            WHERE event_type = 'view'
        ) AS unique_products_viewed,
        COUNT(DISTINCT product_id) FILTER (
            WHERE event_type = 'addtocart'
        ) AS unique_products_added,
        COUNT(DISTINCT product_id) FILTER (
            WHERE event_type = 'transaction'
        ) AS unique_products_purchased
    FROM cd_events_clean
    GROUP BY visitor_id
)
SELECT
    *,
    CASE
        WHEN total_transactions > 0
            THEN 'Purchaser'
        WHEN total_add_to_cart > 0
            THEN 'Cart Abandoner'
        WHEN total_views > 0
            THEN 'Browser'
        ELSE 'Other'
    END AS visitor_segment
FROM visitor_activity;



-- Validating the visitor mart
SELECT
    visitor_segment,
    COUNT(*) AS total_visitors,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS visitor_percentage,
    ROUND(AVG(total_views), 2) AS avg_views,
    ROUND(AVG(total_add_to_cart), 2) AS avg_add_to_cart,
    ROUND(AVG(total_transactions), 2) AS avg_transactions
FROM mart_visitor_behavior
GROUP BY visitor_segment
ORDER BY total_visitors DESC;





-- Creating Product Performance Mart
-- Q. Which products attract user attention but fail to generate purchases?

CREATE OR REPLACE VIEW mart_product_performance AS
WITH product_metrics AS (
    SELECT
        product_id,
        COUNT(*) FILTER (
            WHERE event_type = 'view'
        ) AS total_views,
        COUNT(*) FILTER (
            WHERE event_type = 'addtocart'
        ) AS total_add_to_cart,
        COUNT(*) FILTER (
            WHERE event_type = 'transaction'
        ) AS total_transactions,
        COUNT(DISTINCT visitor_id) FILTER (
            WHERE event_type = 'view'
        ) AS unique_viewers,
        COUNT(DISTINCT visitor_id) FILTER (
            WHERE event_type = 'addtocart'
        ) AS unique_cart_users,
        COUNT(DISTINCT visitor_id) FILTER (
            WHERE event_type = 'transaction'
        ) AS unique_buyers
    FROM cd_events_clean
    GROUP BY product_id
)
SELECT
    *,
    ROUND(
        100.0 * total_add_to_cart /
        NULLIF(total_views, 0),
        2
    ) AS view_to_cart_rate,
    ROUND(
        100.0 * total_transactions /
        NULLIF(total_views, 0),
        2
    ) AS view_to_transaction_rate,
    ROUND(
        100.0 * total_transactions /
        NULLIF(total_add_to_cart, 0),
        2
    ) AS cart_to_transaction_rate
FROM product_metrics;





-- Identifying high-attention, low-conversion products
-- products that attract substantial attention but have relatively weak transaction rates.
SELECT
    product_id,
    total_views,
    total_add_to_cart,
    total_transactions,
    view_to_cart_rate,
    view_to_transaction_rate,
    cart_to_transaction_rate
FROM mart_product_performance
WHERE total_views >= 100
  AND total_transactions > 0
ORDER BY view_to_transaction_rate ASC
LIMIT 20;




-- Identifying high-performing products
SELECT
    product_id,
    total_views,
    total_add_to_cart,
    total_transactions,
    view_to_cart_rate,
    view_to_transaction_rate,
    cart_to_transaction_rate
FROM mart_product_performance
WHERE total_views >= 100
  AND total_transactions > 0
ORDER BY view_to_transaction_rate DESC
LIMIT 20;




-- Daily Product Metrics Mart
-- Q. How does user engagement and purchasing behaviour change over time?
/*  Are daily views increasing or decreasing?
    Are add-to-cart events following the same trend?
    Are transactions growing at the same pace as views?
    Are there days with unusually high engagement but weak purchasing activity? */


CREATE OR REPLACE VIEW mart_daily_product_metrics AS
SELECT
    event_date,
    COUNT(*) FILTER (
        WHERE event_type = 'view'
    ) AS total_views,
    COUNT(*) FILTER (
        WHERE event_type = 'addtocart'
    ) AS total_add_to_cart,
    COUNT(*) FILTER (
        WHERE event_type = 'transaction'
    ) AS total_transactions,
    COUNT(DISTINCT visitor_id) AS daily_active_visitors,
    COUNT(DISTINCT visitor_id) FILTER (
        WHERE event_type = 'view'
    ) AS daily_viewers,
    COUNT(DISTINCT visitor_id) FILTER (
        WHERE event_type = 'addtocart'
    ) AS daily_cart_users,
    COUNT(DISTINCT visitor_id) FILTER (
        WHERE event_type = 'transaction'
    ) AS daily_purchasers
FROM cd_events_clean
GROUP BY event_date
ORDER BY event_date;





-- Calculating daily conversion indicators

CREATE OR REPLACE VIEW mart_daily_conversion_metrics AS
SELECT
    event_date,
    total_views,
    total_add_to_cart,
    total_transactions,
    daily_active_visitors,
    daily_viewers,
    daily_cart_users,
    daily_purchasers,
    ROUND(
        100.0 * total_add_to_cart /
        NULLIF(total_views, 0),
        2
    ) AS daily_view_to_cart_rate,
    ROUND(
        100.0 * total_transactions /
        NULLIF(total_views, 0),
        2
    ) AS daily_view_to_transaction_rate,
    ROUND(
        100.0 * daily_purchasers /
        NULLIF(daily_viewers, 0),
        2
    ) AS daily_viewer_to_purchaser_rate
FROM mart_daily_product_metrics;




-- Identifying unusual days : days with high engagement but comparatively low transaction activity.
SELECT
    event_date,
    total_views,
    total_add_to_cart,
    total_transactions,
    daily_view_to_cart_rate,
    daily_view_to_transaction_rate
FROM mart_daily_conversion_metrics
WHERE total_views > 0
ORDER BY daily_view_to_transaction_rate ASC
LIMIT 15;



-- creating and exporting the files
COPY (SELECT * FROM mart_visitor_behavior ORDER BY visitor_id) TO 'visitor_behavior.csv' (HEADER, DELIMITER ',');
COPY (SELECT * FROM mart_product_performance ORDER BY product_id) TO 'product_performance.csv' (HEADER, DELIMITER ',');
COPY (SELECT * FROM mart_daily_conversion_metrics ORDER BY event_date) TO 'daily_conversion_metrics.csv' (HEADER, DELIMITER ',');

.files download visitor_behavior.csv
.files download product_performance.csv
.files download daily_conversion_metrics.csv