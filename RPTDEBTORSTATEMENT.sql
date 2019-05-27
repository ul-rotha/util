
GO
/****** Object:  StoredProcedure [dbo].[RPTDEBTORSTATEMENT]    Script Date: 05/25/2018 17:00:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[RPTDEBTORSTATEMENT]
( 	
	@DEBTORCODE NVARCHAR(100),
	@CODE as tp_codehelper readonly,
	@DATEFROM INT,
	@TITLE nvarchar(100)
)
AS
BEGIN

	declare @table table(
		DOCDATE nvarchar(100),
		DOCCODE nvarchar(100),
		STOCKCODE nvarchar(100),
		QTY varchar(100),		
		UOM varchar(100),
		UNITPRICE FLOAT,
		AMOUNT FLOAT,
		TOTALAMOUNT FLOAT,
		OUTSTANDING FLOAT,
		REMARK varchar(500),
		ROWSPAN INT,
		FLAG nvarchar(100)
	)
	insert into @table
	SELECT 
	data.[date],
	data.doc_no,
	data.stock_code,
	data.qty,
	data.uom,
	data.unit_price,
	data.amount,
	data.total_amount,
	data.outstanding,
	data.remark,
	data.rowspan,
	case when data.rowspan > 0 then 'flag5' else 'flag6' end
	FROM  
	(  
		SELECT
		cs.csDEBTORACCOUNT [debtor],
		'CS' [type],
		dbo.DateDisplay(cs.csCASHSALESDATE) [date],
		cs.csCASHSALESCODE [doc_no],
		cs.csCASHSALESREFNO [ref_no],
		0 [pos],
		cd.cdSTOCKCODE [stock_code],
		cd.cdQTY [qty],
		cd.cdUOM [uom],
		cd.cdUNITPRICE [unit_price],
		cd.cdDISCOUNT [discount],
		cd.cdAMOUNT [amount],
		ISNULL(cs.csTOTALAMOUNT,0) [total_amount],
		(ISNULL(cs.csTOTALAMOUNT,0)-(SELECT ISNULL(SUM(ahAMOUNT + ahDISCOUNT),0) FROM su_armatched arm WHERE arm.ahPAYFORTYPE='CS' AND arm.ahPAYFORCODE=cs.csCASHSALESCODE AND arm.ahCANCELLED <> 'T'))
		[outstanding],
		cs.csCASHSALESREFNO [remark],
		--cs.csREMARK1 [remark],
		Case when cd.cdPOS=1 then (select COUNT(*) from su_cashsalesdetail l where l.cdCASHSALESCODE = cs.csCASHSALESCODE and ISNULL(l.cdSTOCKCODE, '') <> '') else 0 end[rowspan]
		FROM dbo.su_cashsales cs
		Inner join dbo.su_cashsalesdetail cd on cs.csCASHSALESCODE = cd.cdCASHSALESCODE and ISNULL(cd.cdSTOCKCODE, '') <> ''
		WHERE cs.csCANCELLED <> 'T' AND cs.csPOSTTODEBTORACCOUNT='Y'
		UNION ALL
		SELECT
		iv.ivDEBTORACCOUNT [debtor],
		'INV' [type],
		dbo.DateDisplay(iv.ivINVOICEDATE) [date],
		iv.ivINVOICECODE [doc_no],
		iv.ivINVOICEREFNO [ref_no],
		0 [pos],
		'' [stock_code],
		'' [qty],
		'',
		0 [unit_price],
		'' [discount],
		ISNULL(iv.ivTOTALAMOUNT,0) [amount],
		ISNULL(iv.ivTOTALAMOUNT,0) [total_amount],
		(ISNULL(iv.ivTOTALAMOUNT,0)-(SELECT ISNULL(SUM(ahAMOUNT + ahDISCOUNT),0) FROM su_armatched arm WHERE arm.ahPAYFORTYPE='INV' AND arm.ahPAYFORCODE=iv.ivINVOICECODE  AND arm.ahCANCELLED <> 'T'))
		[outstanding],
		iv.ivNOTE [remark],
		1 [rowspan]
		FROM dbo.su_invoice iv
		WHERE iv.ivCANCELLED <> 'T' and iv.ivINVOICECODE not in (select siSALESINVOICECODE from su_salesinvoice)
		UNION ALL
		SELECT
		s.siDEBTORACCOUNT [debtor],
		'INV' [type],
		dbo.DateDisplay(s.siSALESINVOICEDATE) [date],
		s.siSALESINVOICECODE [doc_no],
		s.siSALESINVOICEREFNO [ref_no],
		0 [pos],
		sd.svSTOCKCODE [stock_code],
		sd.svQTY [qty],
		sd.svUOM [uom],
		sd.svUNITPRICE [unit_price],
		sd.svDISCOUNT [discount],
		sd.svAMOUNT [amount],
		ISNULL(s.siTOTALAMOUNT,0) [total_amount],
		(ISNULL(s.siTOTALAMOUNT,0)-(SELECT ISNULL(SUM(ahAMOUNT + ahDISCOUNT),0) FROM su_armatched arm WHERE arm.ahPAYFORTYPE='INV' AND arm.ahPAYFORCODE=s.siSALESINVOICECODE  AND arm.ahCANCELLED <> 'T'))
		[outstanding],
		s.siSALESINVOICEREFNO [remark],
		--s.siREMARK1 [remark],
		Case when sd.svPOS=1 then (select COUNT(*) from su_salesinvoicedetail l where l.svSALESINVOICECODE = s.siSALESINVOICECODE and ISNULL(l.svSTOCKCODE, '') <> '') else 0 end[rowspan]
		FROM dbo.su_salesinvoice s
		Inner join dbo.su_salesinvoicedetail sd on s.siSALESINVOICECODE = sd.svSALESINVOICECODE and ISNULL(sd.svSTOCKCODE, '') <> ''		
		WHERE s.siCANCELLED <> 'T'
		UNION ALL
		SELECT
		dn.snDEBTORACCOUNT [debtor],
		'DN' [type],
		dbo.DateDisplay(dn.snSALESDNDATE) [date],
		dn.snSALESDNCODE [doc_no],
		dn.snSALESDNREFNO [ref_no],
		0 [pos],
		dnd.stSTOCKCODE [stock_code],
		dnd.stQTY [qty],
		dnd.stUOM [uom],
		dnd.stUNITPRICE [unit_price],
		dnd.stDISCOUNT [discount],
		dnd.stAMOUNT [amount],
		dn.snTOTALAMOUNT [total_amount],
		(dn.snTOTALAMOUNT-(SELECT ISNULL(SUM(ahAMOUNT + ahDISCOUNT),0) FROM su_armatched arm WHERE arm.ahPAYFORTYPE='DN' AND arm.ahPAYFORCODE=dn.snSALESDNCODE AND arm.ahCANCELLED <> 'T'))
		[outstanding],
		dn.snREMARK1 [remark],
		Case when dnd.stPOS=1 then (select COUNT(*) from su_salesdndetail l where l.stSALESDNCODE = dn.snSALESDNCODE and ISNULL(l.stSTOCKCODE, '') <> '') else 0 end[rowspan]
		FROM dbo.su_salesdn dn
		Inner join dbo.su_salesdndetail dnd on dn.snSALESDNCODE = dnd.stSALESDNCODE and ISNULL(dnd.stSTOCKCODE, '') <> ''
		WHERE dn.snCANCELLED <> 'T'
		UNION ALL
		SELECT
		jd.jdGLACCOUNTCODE [debtor],
		'JV' [type],
		dbo.DateDisplay(j.jnJOURNALDATE) [date],
		jd.jdJOURNALCODE [doc_no],
		jd.jdREFERENCE1 [ref_no],
		jd.jdPOS [pos],
		'' [stock_code],
		'' [qty],
		'' [uom],
		0 [unit_price],		
		'' [discount],
		jd.jdFDEBIT [amount],
		jd.jdFDEBIT [total_amount],
		(jd.jdFDEBIT-(SELECT ISNULL(SUM(ahAMOUNT + ahDISCOUNT),0) FROM su_armatched arm WHERE arm.ahPAYFORTYPE='JV' AND arm.ahPAYFORCODE=j.jnJOURNALCODE AND arm.ahPAYFORPOS=jd.jdPOS AND arm.ahCANCELLED <> 'T')) [outstanding],
		j.jnDESCRIPTION [remark],
		1 [rowspan]
		FROM dbo.su_journaldetail jd
		INNER JOIN dbo.su_glaccount ga ON jd.jdGLACCOUNTCODE = ga.gaGLACCOUNTCODE
		INNER JOIN dbo.su_journal j ON j.jnJOURNALCODE = jd.jdJOURNALCODE
		WHERE ga.gaSPECIALACCOUNTCODE = 'AR' AND jd.jdFDEBIT <> 0 AND j.jnCANCELLED <> 'T'
	) data  
	WHERE data.debtor=@DEBTORCODE AND data.outstanding > 0
	and (data.[type]+data.doc_no) in (select chCODE from @CODE)
	
	
	
	declare @returnTable table(
		AUTOID  int identity primary key,
		COL01   nvarchar(500),
		COL02   nvarchar(500),
		COL03   nvarchar(500),
		COL04   nvarchar(500),
		COL05   nvarchar(500),
		COL06   nvarchar(500),
		COL07   nvarchar(500),
		COL08   nvarchar(500),
		COL09   nvarchar(500),
		COL10   nvarchar(500),
		COL11   nvarchar(500),
		COL12   nvarchar(500),
		COL13   nvarchar(500),
		COL14   nvarchar(500),
		COL15   nvarchar(500),
		COL16   nvarchar(500),
		COL17   nvarchar(500),
		COL18   nvarchar(500),
		COL19   nvarchar(500),
		COL20   nvarchar(500),
		COL21   nvarchar(500),
		COL22   nvarchar(500),
		COL23   nvarchar(500),
		COL24   nvarchar(500),
		FLAG    nvarchar(500)
	);
	
	Insert into @returnTable(COL01, FLAG) values((select top 1 cpCOMPANYNAME from su_companyprofile),'company');
	Insert into @returnTable(COL01, FLAG) values(@TITLE,'title');	
	Insert into @returnTable(COL01, FLAG) values('As of ' + dbo.DateDisplay([dbo].[DateIntToDateTime](@DATEFROM)),'subtitle');
	Insert into @returnTable(COL01, FLAG) Values('Customer: ' + @DEBTORCODE + ' - ' + (select top 1 dtCOMPANYNAME2 from su_debtor where dtCOMPANYCODE = @DEBTORCODE), 'flag2');
	Insert into @returnTable(COL01, FLAG) Values('Mobile: ' + (select top 1 dtPHONE1  from su_debtor where dtCOMPANYCODE = @DEBTORCODE), 'flag3');	
	Insert into @returnTable(COL01, FLAG) Values('Address: ' + (select top 1 dtADDRESS2 from su_debtor where dtCOMPANYCODE = @DEBTORCODE), 'flag3');	
	
	
	Insert into @returnTable (COL01, COL02, COL03, COL04, COL05, COL06, COL07, COL08, COL09, COL10, COL11, FLAG)
	Values ('Date', 'Invoice', 'Item', 'Qty', 'UOM', 'Unit Price', 'Amount', 'Total', 'Balance', 'Remark', 'rowspan', 'flag4');	
	
	Insert into @returnTable (COL01, COL02, COL03, COL04, COL05, COL06, COL07, COL08, COL09, COL10, COL11, FLAG)
	SELECT 
	DOCDATE,
	DOCCODE,
	STOCKCODE,
	QTY,	
	UOM,
	dbo.FN_2Money2D(UNITPRICE),
	dbo.FN_2Money2D(AMOUNT),
	dbo.FN_2Money2D(TOTALAMOUNT),
	dbo.FN_2Money2D(OUTSTANDING),
	REMARK,
	ROWSPAN,
	FLAG
	from @table order by dbo.DateToInt(DOCDATE), DOCCODE, ROWSPAN desc;

	select*from @returnTable;
	select dbo.FN_2Money2D(ISNULL(SUM(OUTSTANDING), 0)) from @table where ROWSPAN > 0;
END
