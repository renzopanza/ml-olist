CREATE TEMPORARY TABLE tb_orders_temp AS
	SELECT DISTINCT 
		   t1.order_id , 
		   t2.seller_id 
		   FROM tb_orders AS t1
		   
	LEFT JOIN tb_order_items t2 ON t1.order_id = t2.order_id 
	
	WHERE t1.order_purchase_timestamp < '2018-01-01' 
	AND t1.order_purchase_timestamp >= DATE('2018-01-01', '-6 months')
	AND t2.seller_id IS NOT NULL;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMPORARY TABLE tb_temp AS
	SELECT t2.*, 
		   t1.seller_id
	FROM tb_orders_temp AS t1
	
	LEFT JOIN tb_order_payments AS t2 ON t1.order_id = t2.order_id;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMPORARY TABLE tb_group AS
	SELECT seller_id,payment_type, 
	    COUNT(DISTINCT order_id) AS qtd_order_payments_type, 
	    SUM(payment_value) AS value_order_payments_type
	FROM tb_temp
	GROUP BY seller_id, payment_type
	ORDER BY seller_id, payment_type;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMPORARY TABLE tb_summary_infos AS
	SELECT 
	    seller_id, 
	    SUM(CASE WHEN payment_type = 'credit_card' THEN qtd_order_payments_type ELSE 0 END) AS qtd_order_credit_card,
	    SUM(CASE WHEN payment_type = 'boleto' THEN qtd_order_payments_type ELSE 0 END) AS qtd_order_boleto,
	    SUM(CASE WHEN payment_type = 'voucher' THEN qtd_order_payments_type ELSE 0 END) AS qtd_order_voucher,
	    SUM(CASE WHEN payment_type = 'debit_card' THEN qtd_order_payments_type ELSE 0 END) AS qtd_order_debit_card,
	     
	    SUM(CASE WHEN payment_type = 'credit_card' THEN value_order_payments_type ELSE 0 END) AS value_total_credit_card,
	    SUM(CASE WHEN payment_type = 'boleto' THEN value_order_payments_type ELSE 0 END) AS value_total_boleto,
	    SUM(CASE WHEN payment_type = 'voucher' THEN value_order_payments_type ELSE 0 END) AS value_total_voucher,
	    SUM(CASE WHEN payment_type = 'debit_card' THEN value_order_payments_type ELSE 0 END) AS value_total_debit_card,
	    
	    ROUND(SUM(CASE WHEN payment_type = 'credit_card' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type) * 100, 2) AS percent_order_credit_card,
	    ROUND(SUM(CASE WHEN payment_type = 'boleto' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type) * 100, 2) AS percent_order_boleto,
	    ROUND(SUM(CASE WHEN payment_type = 'voucher' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type) * 100, 2) AS percent_order_voucher,
	    ROUND(SUM(CASE WHEN payment_type = 'debit_card' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type) * 100, 2) AS percent_order_debit_card,
	     
	    ROUND(SUM(CASE WHEN payment_type = 'credit_card' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) * 100, 2) AS percent_total_credit_card,
	    ROUND(SUM(CASE WHEN payment_type = 'boleto' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) * 100, 2) AS percent_total_boleto,
	    ROUND(SUM(CASE WHEN payment_type = 'voucher' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) * 100, 2) AS percent_total_voucher,
	    ROUND(SUM(CASE WHEN payment_type = 'debit_card' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) * 100, 2) AS percent_total_debit_card
	FROM tb_group
	GROUP BY seller_id;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TEMPORARY TABLE tb_info_credit_card AS
	WITH filter_seller_data AS (
	    SELECT 
	        seller_id,
	        payment_installments
	    FROM tb_temp
	    WHERE payment_type = 'credit_card'
	),
	median_foreach_seller_data AS (
	    SELECT 
	        seller_id,
	        AVG(payment_installments) AS median_payment_installments
	    FROM (
	        SELECT 
	            seller_id,
	            payment_installments,
	        ROW_NUMBER() OVER (PARTITION BY seller_id ORDER BY payment_installments) AS row_num,
	        COUNT(*) OVER (PARTITION BY seller_id) AS total_count
	        FROM filter_seller_data
	    )
	    WHERE row_num IN ((total_count + 1) / 2, (total_count + 2) / 2)
	    GROUP BY seller_id
	)
	SELECT 
	    fsd.seller_id,
	    AVG(fsd.payment_installments) AS avg_qtd_installments,
	    m.median_payment_installments,
	    MAX(payment_installments) AS max_installments,
	    MIN(payment_installments) AS min_installments
	
	FROM filter_seller_data fsd
	
	JOIN median_foreach_seller_data m ON fsd.seller_id = m.seller_id
	GROUP BY fsd.seller_id;

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
	'2018-01-01' AS dt_ref, 	--É o nosso carimbo pra sabermos quando essas estatisticas foram implementadas/anotadas na tabela! Depois tera um script para preencher sozinho esta REF 
	t1.*,						-- Neste caso a tabela vai ser como um album de fotos que irá aumentando dia a dia. Cada foto contem uma nova informação sobre a tabela e cada foto terá sua data referencia
	t2.avg_qtd_installments,	-- Assim possibilita sabermos quando a tabela foi preenchida e para qual data as informações estão atreladas.
	t2.median_payment_installments,
	t2.max_installments,
	t2.min_installments
FROM tb_summary_infos t1
LEFT JOIN tb_info_credit_card t2 ON t1.seller_id = t2.seller_id
GROUP BY t1.seller_id;