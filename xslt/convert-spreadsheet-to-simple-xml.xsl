<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
exclude-result-prefixes="ss" xmlns:ss="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
	<xsl:output indent="yes"/>
	
	<xsl:template match="/">
		<xsl:variable name="heading-row" select="ss:worksheet/ss:sheetData/ss:row[1]"/>
		<records>
			<xsl:for-each select="ss:worksheet/ss:sheetData/ss:row[position() &gt; 1]">
				<record>
					<xsl:for-each select="ss:c[normalize-space()][not(.='NULL')]">
						<!-- 
						Each c element (cell) has a grid reference in its @r attribute 
						e.g. r="B3" identifies the cell in row 3, column 2.
						Here we extract the column portion of that identifier: "B", and search within
						the heading row for the cell whose @r = "B1", take the contents of that cell
						("STAFF_ID"), and create an element with that name.
						-->
						<xsl:variable name="column-code" select="translate(@r, '0123456789', '')"/>
						<xsl:variable name="column-name" select="$heading-row/ss:c[@r=concat($column-code, '1')]"/>
						<xsl:if test="not($column-name)">
							<xsl:message terminate="true">
								<xsl:value-of select="concat(
									'No column heading for cell with reference ',
									@r,
									' and content ',
									codepoints-to-string(34),
									.,
									codepoints-to-string(34)
								)"/>
							</xsl:message>
						</xsl:if>
						<xsl:element name="{replace($column-name, ' ', '-')}">
							<xsl:value-of select="ss:v"/>
						</xsl:element>
					</xsl:for-each>
				</record>
			</xsl:for-each>
		</records>
	</xsl:template>

</xsl:stylesheet>

