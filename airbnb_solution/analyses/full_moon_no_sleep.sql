WITH fullmoon_reviews AS (
    SELECT * FROM {{ ref('mart_fullmoon_reviews') }}
)

SELECT
    is_full_moon,
    SUM(CASE WHEN review_sentiment = 'positive' THEN 1 ELSE 0 END)
        AS positive_count,
    COUNT(*) AS total_count,
    ROUND(
        SUM(CASE WHEN review_sentiment = 'positive' THEN 1 ELSE 0 END)
        * 100.0
        / COUNT(*),
        2
    ) AS positive_percentage
FROM
    fullmoon_reviews
WHERE
    review_sentiment != 'neutral'
GROUP BY
    is_full_moon
ORDER BY
    is_full_moon
