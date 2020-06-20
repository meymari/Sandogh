DROP PROCEDURE sp_fund_volume_chart;
DELIMITER $$
CREATE PROCEDURE `sp_fund_volume_chart`()
BEGIN
	SELECT "Start sp_fund_volume_chart";
	DELETE FROM fund_industry WHERE deleted = 1;
    DELETE FROM fund_share    WHERE deleted = 1;
    DELETE FROM fund_asset    WHERE deleted = 1;
    DELETE FROM symbol_value  WHERE deleted = 1;
    
	SET @l_min_date_industry = (SELECT COALESCE(MIN(date),(SELECT MAX(date) from fund_industry)) from fund_industry where chart is null or chart = false);
	SET @l_min_date_share    = (SELECT COALESCE(MIN(date),(SELECT MAX(date) from fund_share   )) from fund_share    where chart is null or chart = false);
	SET @l_min_date_asset    = (SELECT COALESCE(MIN(date),(SELECT MAX(date) from fund_asset   )) from fund_asset    where chart is null or chart = false);
	SET @l_min_date_symbol   = (SELECT COALESCE(MIN(date),(SELECT MAX(date) from symbol_value )) from symbol_value  where chart is null or chart = false);
	SET @l_max_date_chart    = (SELECT COALESCE(MAX(date),'1399/01/01') from fund_volume_chart);
	
    SET @l_min_date = @l_min_date_industry;
    IF @l_min_date_share < @l_min_date THEN
      SET @l_min_date = @l_min_date_share;
    END IF;   
    IF @l_min_date_asset < @l_min_date THEN
      SET @l_min_date = @l_min_date_asset;
    END IF;   
	IF @l_min_date_symbol < @l_min_date THEN
      SET @l_min_date = @l_min_date_symbol;
    END IF;
	IF (@l_max_date_chart is not null && @l_max_date_chart < @l_min_date) THEN
      SET @l_min_date = @l_max_date_chart;
    END IF;
	IF (@l_min_date < '1399/01/01') THEN
      SET @l_min_date = '1399/01/01';
    END IF;
	
	SELECT 
		@l_min_date as l_min_date, 
		@l_min_date_industry AS l_min_date_industry, 
		@l_min_date_share AS l_min_date_share, 
		@l_min_date_asset AS l_min_date_asset, 
		@l_min_date_symbol AS l_min_date_symbol, 
		@l_max_date_chart As l_max_date_chart;
    
    SET @l_max_date_industry = (SELECT MAX(created_at) from fund_industry);
    SET @l_max_date_share    = (SELECT MAX(created_at) from fund_share   );
    SET @l_max_date_asset    = (SELECT MAX(created_at) from fund_asset   );
    SET @l_max_date_symbol   = (SELECT MAX(created_at) from symbol_value );
	
	SELECT 
		@l_max_date_industry as l_max_date_industry, 
		@l_max_date_share AS l_max_date_share, 
		@l_max_date_asset AS l_max_date_asset, 
		@l_max_date_symbol AS l_max_date_symbol;

    DELETE FROM fund_volume_chart WHERE `date` >= @l_min_date;
	     
	UPDATE fund_share AS fs 
    SET nav_stock = (
		SELECT fs.NAV*fund_asset.Stock/100 FROM fund_asset
    	where fund_asset.fund_code = fs.fund_code AND fund_asset.Date = fs.Date and fund_asset.deleted = 0
	)
    where nav_stock = 0 or nav_stock is null;      
    
    UPDATE fund_share AS fs 
	SET ratio = fs.nav_stock /(SELECT sum(nav_stock) FROM fund_share WHERE fund_share.DATE = fs.DATE and fund_share.deleted = 0)* 100
    WHERE fs.DATE >= @l_min_date;
	
    UPDATE fund_industry AS fi
	SET industry_code = (SELECT industry_code FROM industry WHERE industry.name = fi.industry_name)
	where fi.fund_industry is null;
	
	
	
    UPDATE fund_industry AS fi
	SET ratio = (
		SELECT float_ratio FROM vw_power_industry 
		WHERE 
			vw_power_industry.date = fi.date and 
			vw_power_industry.fund_code = fi.fund_code and
			vw_power_industry.industry_code = fi.industry_code		
	)
    WHERE fs.DATE >= @l_min_date;	
   
	INSERT INTO fund_volume_chart(`date`,industry_code,ratio)
	SELECT fi.`date`, industry_code, ROUND(SUM(industry_ratio),1) AS ratio
	FROM vw_fund_industry fi
    WHERE fi.Date >= @l_min_date AND fi.type Like '%A%'
	GROUP BY fi.`date`, industry_code; 
    
	UPDATE `fund_industry` SET `chart`=true
	where (`date` >= @l_min_date) AND (created_at <= @l_max_date_industry);
    
	UPDATE `fund_share` SET `chart`=true
	where (`date` >= @l_min_date) and (created_at <= @l_max_date_share);
    
	UPDATE `fund_asset` SET `chart`=true
	where (`date` >= @l_min_date) and (created_at <= @l_max_date_asset);
    
    UPDATE `symbol_value` SET `chart`=true
	where (`date` >= @l_min_date) and (created_at <= @l_max_date_symbol);

	SET @LEAVE = 0;
	SET @Count_Fund = (select Count(*) FROM fund WHERE fund.active = 1);
	REPEAT
		SET @Max_Date_Today   = (SELECT Max(date) FROM fund_volume_chart);
		SET @Count_Fund_Today = (SELECT Count(*)  FROM (SELECT fund_code,date FROM fund_industry WHERE date=@Max_Date_Today GROUP BY fund_code,date) a);
    	IF @Count_Fund_Today < (@Count_Fund * 7 / 8) THEN
      		DELETE FROM fund_volume_chart WHERE date = @Max_Date_Today;
			SELECT @Max_Date_Today As 'Delete Chart Date'; 
        ELSE
   			SET @LEAVE = 1;          
    	END IF;
    UNTIL @LEAVE = 1
    END REPEAT;   
	SELECT "End sp_fund_volume_chart";	
END$$
DELIMITER ;