<!-- transclude shared strings in an Excel spreadsheet -->
<!-- Input document is <wrapper> containing sheet and shared string table -->
<!-- Output is sheet with strings inline -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" 
	exclude-result-prefixes="ss" xmlns:ss="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
	
	<xsl:key name="string-by-index" match="/wrapper/ss:sst/ss:si" use="count(preceding-sibling::ss:si)"/>
	
	<xsl:template match="wrapper">
		<xsl:apply-templates select="ss:worksheet"/>
	</xsl:template>
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:apply-templates select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@*">
		<xsl:copy-of select="."/>
	</xsl:template>
	
	<xsl:template match="ss:c/@t"/>
	
	<xsl:template match="ss:c[@t='s']/ss:v/text()">
		<xsl:variable name="index" select="number(.)"/>
		<xsl:value-of select="key('string-by-index', $index)"/>
	</xsl:template>
	
</xsl:stylesheet>
