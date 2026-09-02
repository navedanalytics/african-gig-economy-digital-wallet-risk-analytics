# The African Gig Economy & Digital Wallet Risk Dashboard

![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Python](https://img.shields.io/badge/Python-EDA%20%26%20Visualization-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Analytics-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![Pandas](https://img.shields.io/badge/Pandas-Data%20Analysis-150458?style=for-the-badge&logo=pandas&logoColor=white)

**Author:** Naved Khan
**Tools:** Power BI (dashboard) · Excel/SQL/Python (data prep) · DAX (measures)

**Type:** Portfolio analytics project — fraud & risk analytics for digital wallets used by gig economy workers across Ghana, Kenya, Nigeria, and South Africa

---

## 📊 Dashboard Preview

<img src="dashbaord/power%20bi/african_gig_economy_digital_wallet_visualization_01.png"
     alt="African Gig Economy and Digital Wallet Risk Dashboard - Page 1"
     width="1200">

<br>

<img src="dashbaord/power%20bi/african_gig_economy_digital_wallet_visualization_02.png"
     alt="African Gig Economy and Digital Wallet Risk Dashboard - Page 2"
     width="1200">

<br>

<img src="dashbaord/power%20bi/african_gig_economy_digital_wallet_visualization_03.png"
     alt="African Gig Economy and Digital Wallet Risk Dashboard - Page 3"
     width="1200">




## 1. Business Problem

Digital wallets are the primary way gig workers (ride-hailing drivers, delivery couriers, domestic workers, freelancers, agricultural day labourers, etc.) get paid across Africa. That convenience comes with exposure: thin KYC files, irregular/high-velocity cash-in/cash-out patterns, and multiple payment rails (Mobile App, USSD, Agent, POS, API/Third-Party) create fraud surface area that's expensive for wallet providers and risky for workers who depend on uninterrupted access to their earnings.

**The core question this project answers:**
> Where is fraud loss concentrated (market, channel, KYC tier, worker segment), what's driving low transaction completion, and what should the business actually *do* about it?

## 2. Dashboard Structure

Three linked pages, filterable by Year/Month:

| Page | Focus |
|---|---|
| **Executive Overview** | Volume, value, fraud loss, and completion trends at a glance |
| **Channel & Market Performance** | Channel efficiency, processing speed, transaction-type revenue mix, country-level regulatory tiers |
| **Fraud & Risk Intelligence** | KYC-tier exposure, gig-segment risk, velocity vs. fraud correlation |

## 3. Key Insights

1. **Fraud is flagged on ~1 in 2 transactions.** A 50.29% flagged-fraud rate against a 12.64% completion rate signals a funnel problem, not a niche edge case — this is systemic, not isolated.
2. **No single "bad market."** Ghana, Kenya, Nigeria, and South Africa each carry near-identical transaction value (~$6.2–6.3M) and fraud loss (~$3.1–3.2M). Fraud exposure is structural to the product, not a country-specific anomaly — even though Nigeria sits in a different regulatory tier (Emerging/Tier 3) than the other three (Mature/Tier 1).
3. **Unverified users punch above their weight.** Tier 0 (unverified) KYC accounts for the highest fraud loss and rate of any tier, and represents 26.1% of total losses on its own.
4. **"High risk" is the norm, not the exception, in this worker base.** 74.31% of active workers are flagged high-risk (1,284 workers) — a rate that high suggests the risk model may be over-flagging as much as it's catching genuine bad actors.
5. **Velocity alone doesn't predict fraud.** Fraud rate stays in a narrow 48–52% band across the full range of velocity scores (490–510) and across every worker segment — velocity is a weak standalone signal.
6. **USSD is the slowest and most volume-light channel** (502.33ms average processing vs. 499.35ms for POS), which matters because USSD is typically the access point for workers on feature phones or in low-connectivity areas.
7. **Completion isn't failing for one reason.** Declined, disputed, failed, pending, reversed, and timeout outcomes are all clustered around 12–13% each — the funnel is leaking evenly across many failure modes, not one dominant cause.
8. **Fraud loss concentrates in four gig segments**: Domestic Workers, E-commerce Resellers, Agricultural Day Labourers, and Tutors/Private Instructors each carry $0.77M–$0.9M in losses with fraud rates of 50–52%.

> **Data note:** This dashboard runs on a simulated/portfolio dataset, which is why several metrics cluster tightly around 50%. The recommendations below are written to demonstrate the *analytical approach and decision framework* a risk/analytics team would apply — reframe with real production data before acting on specific thresholds.

## 4. Recommendations to Stakeholders

| Insight | Recommendation | Owner |
|---|---|---|
| ~50% flag rate with low completion | Recalibrate fraud-rule thresholds and introduce a **tiered review queue** (auto-clear low-risk, human review mid-risk, auto-block high-risk) instead of one blanket flag | Risk/Fraud Ops |
| Fraud loss evenly spread across 4 markets | Standardize a **core control set** across all markets, with a local regulatory overlay for Nigeria's Tier 3 status rather than four bespoke rulebooks | Compliance + Regional Leads |
| Tier 0 (unverified) drives outsized loss | Introduce **step-up KYC**: cap transaction size/velocity for Tier 0 until phone/ID verification, with a low-friction in-app upgrade flow | Product + Compliance |
| 74% of workers flagged high-risk | Move from a single blanket risk score to **segment-specific models** (gig-type, income pattern, tenure) — a domestic worker's cash-flow pattern isn't a driver's | Data Science |
| Velocity is a weak standalone predictor | Combine velocity with **device fingerprinting, geolocation, and KYC tier** into a composite risk score rather than flagging on velocity alone | Data Science |
| USSD is slowest, likely serves the least-connected workers | Prioritize **USSD infrastructure investment** — this is a financial-inclusion issue as much as a performance one | Engineering |
| Completion loss spread across many failure types | Run **outcome-specific fixes**: retry/backoff logic for timeouts, real-time decisioning for declines, SLA-bound resolution for disputes | Product Ops |
| 4 gig segments drive concentrated fraud loss | Pilot **targeted interventions** (biometric re-verification, financial literacy nudges, transaction limits) for Domestic Worker, E-commerce Reseller, Agricultural Day Labourer, and Tutor segments before rolling out platform-wide | Risk + Product |

## 5. Monitoring & Continuous Improvement

Recommendations only matter if their impact is tracked. Proposed monitoring loop:

**Core KPIs to watch weekly:**
- Fraud loss ($ and % of transaction value), by market and channel
- Flagged-fraud rate vs. confirmed-fraud rate (to catch over-flagging / false positives)
- Completion rate, broken out by failure type (declined, timeout, disputed, etc.)
- KYC tier migration rate (Tier 0 → Tier 1+) after step-up prompts launch
- % of workers in the "high-risk" band, tracked after any risk-model recalibration

**Cadence:**
- **Weekly** — Ops review of fraud queue volume, false-positive rate, and channel processing times
- **Monthly** — Stakeholder report on fraud loss trend, completion rate trend, and segment-level fraud loss vs. prior month
- **Quarterly** — Full risk-model recalibration review; re-test whether velocity/KYC/device composite scoring is actually outperforming the old single-signal model

**Feedback loop:**
1. Ship a change (e.g., new Tier 0 transaction cap) as an **A/B test** against a control group where possible.
2. Compare fraud loss, completion rate, and legitimate-user friction (support tickets, drop-off) between test and control after 2–4 weeks.
3. Roll forward only if fraud loss drops **without** a matching spike in legitimate-transaction friction.
4. Feed results back into the dashboard so the same view used to diagnose the problem is used to confirm the fix worked — closing the loop between insight → action → measurement.

## 6. PDF File in This Repo

African gig economy and digital wallet risk  visualization.pdf
in ../dashbaords/power Bi/African gig economy and digital wallet risk  visualization.pdf


# african-gig-economy-digital-wallet-risk-analytics
An end-to-end data analytics project analyzing transaction performance, fraud exposure, digital wallet activity, risk patterns, and operational performance across African markets using SQL, Python, and Power BI.

