CREATE TEMPORARY TABLE tb_temp AS
	SELECT t2.*, t3.seller_id
	FROM tb_orders AS t1
	
	LEFT JOIN tb_order_payments AS t2 ON t1.order_id = t2.order_id
	LEFT JOIN tb_order_items AS t3 ON t1.order_id = t3.order_id
	
	WHERE t1.order_purchase_timestamp < '2018-01-01' 
	AND t1.order_purchase_timestamp >= DATE('2018-01-01', '-6 months')
	AND t3.seller_id IS NOT NULL;


CREATE TEMPORARY TABLE tb_group AS
	SELECT seller_id,payment_type, 
	    COUNT(DISTINCT order_id) AS qtd_order_payments_type, 
	    SUM(payment_value) AS value_order_payments_type
	FROM tb_temp
	GROUP BY seller_id, payment_type
	ORDER BY seller_id, payment_type;

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
    
    
    SUM(CASE WHEN payment_type = 'credit_card' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type) AS percent_order_credit_card,
    SUM(CASE WHEN payment_type = 'boleto' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type)  AS percent_order_boleto,
    SUM(CASE WHEN payment_type = 'voucher' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type)  AS percent_order_voucher,
    SUM(CASE WHEN payment_type = 'debit_card' THEN qtd_order_payments_type ELSE 0 END) / SUM(qtd_order_payments_type)  AS percent_order_debit_card,
     
    SUM(CASE WHEN payment_type = 'credit_card' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) AS percent_total_credit_card,
    SUM(CASE WHEN payment_type = 'boleto' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) AS percent_total_boleto,
    SUM(CASE WHEN payment_type = 'voucher' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) AS percent_total_voucher,
    SUM(CASE WHEN payment_type = 'debit_card' THEN value_order_payments_type ELSE 0 END) / SUM(value_order_payments_type) AS percent_total_debit_card
FROM tb_group
GROUP BY 1;