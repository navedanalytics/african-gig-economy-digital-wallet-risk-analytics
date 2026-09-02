sql = SQL Analysis — African Gig Economy & Digital Wallet Risk Dashboard
-- SQL
-- Columns used are based on the merged transaction table provided.

-- 1. Total transaction count and value by country
SELECT country,
COUNT(*) AS total_transactions,
ROUND(SUM(amount_usd),2) AS total_transaction_value_usd
FROM transactions
GROUP BY country
ORDER BY total_transaction_value_usd DESC;

-- 2. Monthly transaction volume and fraud loss trend
SELECT DATE_TRUNC('month',full_date) AS txn_month,
COUNT(*) AS total_transactions,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY DATE_TRUNC('month',full_date)
ORDER BY txn_month;

-- 3. Transaction outcome count and percentage share
SELECT transaction_outcome,
COUNT(*) AS transaction_count,
ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER(),2) AS percentage_share
FROM transactions
GROUP BY transaction_outcome
ORDER BY transaction_count DESC;

-- 4. Average transaction value by channel
SELECT channel_type,
ROUND(AVG(amount_usd),2) AS average_transaction_value_usd,
COUNT(*) AS transaction_count
FROM transactions
GROUP BY channel_type
ORDER BY average_transaction_value_usd DESC;

-- 5. Total fraud loss and fraud rate by KYC tier
SELECT kyc_tier,
COUNT(*) AS total_transactions,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct
FROM transactions
GROUP BY kyc_tier
ORDER BY kyc_tier;

-- 6. Completion rate by country
SELECT country,
COUNT(*) AS total_transactions,
ROUND(100.0*SUM(CASE WHEN transaction_outcome='Completed' THEN 1 ELSE 0 END)/COUNT(*),2) AS completion_rate_pct
FROM transactions
GROUP BY country
ORDER BY completion_rate_pct DESC;

-- 7. Channel with the highest average processing time
SELECT channel_type,
ROUND(AVG(processing_time_ms),2) AS average_processing_time_ms
FROM transactions
GROUP BY channel_type
ORDER BY average_processing_time_ms DESC
LIMIT 1;

-- 8. Gig segments ranked by total fraud loss
SELECT gig_segment,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd,
RANK() OVER(ORDER BY SUM(fraud_loss_usd) DESC) AS fraud_loss_rank
FROM transactions
GROUP BY gig_segment
ORDER BY fraud_loss_rank;

-- 9. Month-over-month percentage change in fraud loss
WITH monthly_loss AS(
SELECT DATE_TRUNC('month',full_date) AS txn_month,
SUM(fraud_loss_usd) AS total_loss
FROM transactions
GROUP BY DATE_TRUNC('month',full_date)
)
SELECT txn_month,
ROUND(total_loss,2) AS total_loss,
ROUND(LAG(total_loss) OVER(ORDER BY txn_month),2) AS previous_month_loss,
ROUND(100.0*(total_loss-LAG(total_loss) OVER(ORDER BY txn_month))/NULLIF(LAG(total_loss) OVER(ORDER BY txn_month),0),2) AS month_over_month_change_pct
FROM monthly_loss
ORDER BY txn_month;

-- 10. Workers whose fraud rate is above the overall average
WITH worker_fraud AS(
SELECT worker_id,
worker_name,
100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*) AS fraud_rate
FROM transactions
GROUP BY worker_id,worker_name
),
overall_rate AS(
SELECT 100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*) AS average_fraud_rate
FROM transactions
)
SELECT worker_id,
worker_name,
ROUND(fraud_rate,2) AS fraud_rate_pct
FROM worker_fraud
CROSS JOIN overall_rate
WHERE fraud_rate>average_fraud_rate
ORDER BY fraud_rate DESC;

-- 11. Top 3 transaction types by transaction value for each country
WITH ranked AS(
SELECT country,
transaction_type,
SUM(amount_usd) AS total_transaction_value_usd,
ROW_NUMBER() OVER(PARTITION BY country ORDER BY SUM(amount_usd) DESC) AS row_num
FROM transactions
GROUP BY country,transaction_type
)
SELECT country,
transaction_type,
ROUND(total_transaction_value_usd,2) AS total_transaction_value_usd
FROM ranked
WHERE row_num<=3
ORDER BY country,row_num;

-- 12. Three-month rolling average of fraud loss
WITH monthly_loss AS(
SELECT DATE_TRUNC('month',full_date) AS txn_month,
SUM(fraud_loss_usd) AS total_loss
FROM transactions
GROUP BY DATE_TRUNC('month',full_date)
)
SELECT txn_month,
ROUND(total_loss,2) AS total_fraud_loss_usd,
ROUND(AVG(total_loss) OVER(ORDER BY txn_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS rolling_3_month_average
FROM monthly_loss
ORDER BY txn_month;

-- 13. High velocity plus Tier 0 KYC risk segment versus other transactions
SELECT CASE WHEN velocity_score>500 AND kyc_tier=0 THEN 'High Velocity + Tier 0' ELSE 'Other Transactions' END AS risk_group,
COUNT(*) AS transaction_count,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY CASE WHEN velocity_score>500 AND kyc_tier=0 THEN 'High Velocity + Tier 0' ELSE 'Other Transactions' END
ORDER BY fraud_rate_pct DESC;

-- 14. Fraud rate for verified versus unverified KYC tiers
SELECT CASE WHEN kyc_tier=0 THEN 'Unverified' ELSE 'Verified' END AS verification_group,
COUNT(*) AS transaction_count,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct
FROM transactions
GROUP BY CASE WHEN kyc_tier=0 THEN 'Unverified' ELSE 'Verified' END;

-- 15. Gig segments with fraud rate above the median
WITH segment_fraud AS(
SELECT gig_segment,
100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*) AS fraud_rate
FROM transactions
GROUP BY gig_segment
),
median_rate AS(
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY fraud_rate) AS median_fraud_rate
FROM segment_fraud
)
SELECT sf.gig_segment,
ROUND(sf.fraud_rate,2) AS fraud_rate_pct
FROM segment_fraud sf
CROSS JOIN median_rate mr
WHERE sf.fraud_rate>mr.median_fraud_rate
ORDER BY sf.fraud_rate DESC;

-- 16. Fraud rate by velocity score bucket
SELECT CASE
WHEN velocity_score<495 THEN 'Below 495'
WHEN velocity_score<500 THEN '495-499'
WHEN velocity_score<505 THEN '500-504'
ELSE '505+'
END AS velocity_bucket,
COUNT(*) AS transaction_count,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct
FROM transactions
GROUP BY CASE
WHEN velocity_score<495 THEN 'Below 495'
WHEN velocity_score<500 THEN '495-499'
WHEN velocity_score<505 THEN '500-504'
ELSE '505+'
END
ORDER BY MIN(velocity_score);

-- 17. Top 20 workers by flagged fraud ratio
SELECT worker_id,
worker_name,
COUNT(*) AS total_transactions,
SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END) AS flagged_fraud_transactions,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_flag_ratio_pct
FROM transactions
GROUP BY worker_id,worker_name
ORDER BY fraud_flag_ratio_pct DESC
LIMIT 20;

-- 18. Workers with more than 10 transactions on the same day
SELECT worker_id,
worker_name,
full_date::date AS transaction_date,
COUNT(*) AS transactions_that_day
FROM transactions
GROUP BY worker_id,worker_name,full_date::date
HAVING COUNT(*)>10
ORDER BY transactions_that_day DESC;

-- 19. Country, channel and KYC combination with highest fraud loss
SELECT country,
channel_type,
kyc_tier,
COUNT(*) AS transaction_count,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY country,channel_type,kyc_tier
ORDER BY total_fraud_loss_usd DESC
LIMIT 10;

-- 20. Estimated transaction value recovered from a 2 percentage-point decline reduction
WITH base AS(
SELECT COUNT(*) AS total_transactions,
SUM(CASE WHEN transaction_outcome='Declined' THEN 1 ELSE 0 END) AS declined_transactions,
AVG(amount_usd) AS average_transaction_value_usd
FROM transactions
)
SELECT total_transactions,
declined_transactions,
ROUND(average_transaction_value_usd,2) AS average_transaction_value_usd,
ROUND(total_transactions*0.02,0) AS estimated_transactions_recovered,
ROUND(total_transactions*0.02*average_transaction_value_usd,2) AS estimated_recovered_value_usd
FROM base;

-- 21. Worker risk-score quartiles and average fraud loss
WITH worker_quartiles AS(
SELECT worker_id,
risk_score,
NTILE(4) OVER(ORDER BY risk_score) AS risk_quartile
FROM transactions
GROUP BY worker_id,risk_score
)
SELECT wq.risk_quartile,
COUNT(DISTINCT wq.worker_id) AS worker_count,
ROUND(AVG(t.fraud_loss_usd),2) AS average_fraud_loss_per_transaction
FROM worker_quartiles wq
JOIN transactions t ON t.worker_id=wq.worker_id
GROUP BY wq.risk_quartile
ORDER BY wq.risk_quartile;

-- 22. Month-to-month KYC tier movement from Tier 0 to Tier 1+
WITH monthly_tier AS(
SELECT worker_id,
DATE_TRUNC('month',full_date) AS txn_month,
MAX(kyc_tier) AS tier_that_month
FROM transactions
GROUP BY worker_id,DATE_TRUNC('month',full_date)
),
tier_change AS(
SELECT worker_id,
txn_month,
tier_that_month,
LAG(tier_that_month) OVER(PARTITION BY worker_id ORDER BY txn_month) AS previous_tier
FROM monthly_tier
)
SELECT worker_id,
txn_month,
previous_tier,
tier_that_month
FROM tier_change
WHERE previous_tier=0 AND tier_that_month>0
ORDER BY txn_month;

-- 23. Channels where decline rate increased for two consecutive months
WITH monthly_decline AS(
SELECT channel_type,
DATE_TRUNC('month',full_date) AS txn_month,
100.0*SUM(CASE WHEN transaction_outcome='Declined' THEN 1 ELSE 0 END)/COUNT(*) AS decline_rate
FROM transactions
GROUP BY channel_type,DATE_TRUNC('month',full_date)
),
with_previous AS(
SELECT channel_type,
txn_month,
decline_rate,
LAG(decline_rate) OVER(PARTITION BY channel_type ORDER BY txn_month) AS previous_decline_rate
FROM monthly_decline
),
changes AS(
SELECT channel_type,
txn_month,
decline_rate,
decline_rate-previous_decline_rate AS current_change,
LAG(decline_rate-previous_decline_rate) OVER(PARTITION BY channel_type ORDER BY txn_month) AS previous_change
FROM with_previous
)
SELECT channel_type,
txn_month,
ROUND(decline_rate,2) AS decline_rate_pct,
ROUND(current_change,2) AS current_change,
ROUND(previous_change,2) AS previous_change
FROM changes
WHERE current_change>0 AND previous_change>0
ORDER BY channel_type,txn_month;

-- 24. Average risk score and fraud rate by gig segment
SELECT gig_segment,
COUNT(*) AS transaction_count,
ROUND(AVG(risk_score),2) AS average_risk_score,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY gig_segment
ORDER BY fraud_rate_pct DESC;

-- 25. Digital versus non-digital transaction risk
SELECT CASE WHEN is_digital='True' OR is_digital=true THEN 'Digital' ELSE 'Non-Digital' END AS transaction_channel_group,
COUNT(*) AS transaction_count,
ROUND(AVG(amount_usd),2) AS average_transaction_value_usd,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY CASE WHEN is_digital='True' OR is_digital=true THEN 'Digital' ELSE 'Non-Digital' END;

-- 26. Fraud loss by country
SELECT country,
COUNT(*) AS total_transactions,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd,
ROUND(100.0*SUM(fraud_loss_usd)/NULLIF(SUM(SUM(fraud_loss_usd)) OVER(),0),2) AS fraud_loss_share_pct
FROM transactions
GROUP BY country
ORDER BY total_fraud_loss_usd DESC;

-- 27. Fraud rate by transaction type
SELECT transaction_type,
COUNT(*) AS transaction_count,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY transaction_type
ORDER BY fraud_rate_pct DESC;

-- 28. High-risk workers based on risk score

SELECT worker_id,
worker_name,
gig_segment,
risk_score,
kyc_tier,
account_tenure_days,
COUNT(*) AS transaction_count,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
WHERE risk_score>=70
GROUP BY worker_id,worker_name,gig_segment,risk_score,kyc_tier,account_tenure_days
ORDER BY risk_score DESC,total_fraud_loss_usd DESC
LIMIT 20;

-- 29. Fraud rate by country and KYC tier
SELECT country,
kyc_tier,
COUNT(*) AS transaction_count,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY country,kyc_tier
ORDER BY country,kyc_tier;

-- 30. Monthly fraud rate for continuous monitoring
SELECT DATE_TRUNC('month',full_date) AS txn_month,
COUNT(*) AS total_transactions,
SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END) AS fraudulent_transactions,
ROUND(100.0*SUM(CASE WHEN is_fraud_flagged='True' OR is_fraud_flagged=true THEN 1 ELSE 0 END)/COUNT(*),2) AS fraud_rate_pct,
ROUND(SUM(fraud_loss_usd),2) AS total_fraud_loss_usd
FROM transactions
GROUP BY DATE_TRUNC('month',full_date)
ORDER BY txn_month;

Real-world solutions / stakeholder actions
1. If Tier 0 has the highest fraud rate or fraud loss, introduce step-up KYC before high-value or high-velocity transactions.
2. If a specific country + channel + KYC combination has high fraud loss, apply targeted controls to that combination instead of restricting every customer.
3. If high velocity transactions show materially higher fraud rates, use velocity as one input in a risk score and trigger review or temporary limits when combined with other risk signals.
4. If a gig segment has high fraud loss but normal fraud rate, investigate transaction volume and value before applying blanket restrictions.
5. If one channel has a consistently high processing time or rising decline rate, send the issue to the operations/technology team for performance investigation.
6. If individual workers have unusually high fraud ratios, prioritize those accounts for review rather than restricting the entire gig segment.
7. Track fraud rate, fraud loss, completion rate, decline rate, processing time and KYC movement monthly to measure whether each intervention is improving outcomes.
8. Compare the latest month with the previous month and the 3-month rolling average. Escalate when fraud loss or decline rate rises consistently rather than reacting to one abnormal day.
9. Review false positives after controls are introduced. If legitimate transactions are being blocked, tune thresholds so fraud reduction does not unnecessarily reduce completion.
10. Use a simple stakeholder monitoring cycle: Identify the highest-risk area -> apply targeted control -> monitor KPIs -> compare with baseline -> adjust the rule -> repeat.


path = Path("/mnt/data/african_gig_wallet_risk_sql_analysis.sql")
path.write_text(sql, encoding="utf-8")
print(f"Created: {path}")
print(f"Queries: 30")
