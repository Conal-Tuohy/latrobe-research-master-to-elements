<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns="http://www.symplectic.co.uk/publications/api">
	<xsl:param name="host" select=" 'sympdev.latrobe.edu.au' "/>
	<xsl:variable name="host-and-port" select="concat($host, ':8091')"/>
	<xsl:key name="research-master-records-by-id" match="/data/records[2]/record" use="ECODE"/>
	<xsl:template match="/data">
		<xsl:copy>
			<!-- the first "records" element contains the stub document records from Elements: for each of these we will need to output an Elements <update-record,
			where the content of each update comes from one or more Research Master records; those which refer to the same document as the Elements record. -->
			<xsl:variable name="elements-records" select="records[1]"/>
			<xsl:variable name="research-master-records" select="records[2]"/>
			<!-- for each of the stub records in Elements which represents a distinct publication, generate an update -->
			<!--<xsl:for-each select="$elements-records/record[position() &lt;= 5000]">-->
			<xsl:for-each select="$elements-records/record">
				<xsl:variable name="elements-id" select="MID"/>
				<xsl:variable name="research-master-id" select="Data-Source-Proprietary-ID"/>
				<xsl:variable name="research-master-records" select="key('research-master-records-by-id', $research-master-id)"/>
				<!-- what happens to the "RID_New?" What is it good for ? -->
				<xsl:variable name="new-research-master-id" select="$research-master-records[1]/RID_New"/>
				<!-- patch-uri e.g. https://sympdev.latrobe.edu.au:8091/elements-api/v4.9/publication/records/c-inst-1/0100024275 -->
				<xsl:variable name="patch-uri" select="concat('https://', $host, ':8091/elements-api/v4.9/publication/records/', 'c-inst-1', '/', '0', $research-master-id)"/>
				<patch uri="{$patch-uri}" xmlns="">
					<update-record xmlns="http://www.symplectic.co.uk/publications/api">
						<!--
						<xsl:comment>Elements ID=<xsl:value-of select="$elements-id"/></xsl:comment>
						<xsl:comment>Research Master ID ("ECODE")=<xsl:value-of select="$research-master-id"/></xsl:comment>
						-->
						<xsl:comment><xsl:value-of select="$patch-uri"/></xsl:comment>
						<xsl:comment><xsl:value-of select="concat('https://', $host, '/viewobject.html?id=', $elements-id, '&amp;cid=1')"/></xsl:comment>
						<!-- the associated research master records describe the document and also the authors -->
						<!-- There is one row per author, so the author properties will vary, but the document properties will be the same in all associated rows -->
						<!-- so it's sufficient to select the first row and copy document properties from that -->
						<fields>
							<xsl:variable name="document-properties" select="$research-master-records[1]"/>
							<xsl:apply-templates select="$document-properties/*" mode="document-properties"/>
							<!--
							It doesn't appear that the author data actually needs patching
							<field name="authors" operation="set">
								<people>
									<xsl:for-each select="$research-master-records">
										<person>
											<xsl:apply-templates select="." mode="debug-output"/>
											<xsl:apply-templates mode="author-properties"/>
										</person>
									</xsl:for-each>
								</people>
							</field>
							-->
						</fields>
					</update-record>
				</patch>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="record" mode="debug-output">
		<xsl:comment>
			<xsl:value-of separator="&#xA;" select="
				(
					'Research Master source record:',
					for $field in * return concat(
						local-name($field),
						': &quot;',
						$field,
						'&quot;'
					)
				)
			"/>
		</xsl:comment>
	</xsl:template>
	
	<!-- TODO add a <link> element with the URI pointing to the staff member using their STAFF_ID -->
	<!--
	<xsl:template mode="author-properties" match="STAFF_ID">
		<links>
			<link type="elements/user" id="{STAFF_ID}" href="{STAFF_ID}"/>
		</links>
	</xsl:template>
	-->
	
	<xsl:template mode="document-properties" match="*"/>
	<xsl:template mode="author-properties" match="*"/>
	<!-- ignoring:
		author full name 
	-->


	
	<!-- rendering publication properties -->
	<!--
ECODE: "100000916" - no need to update since this is the key we used to look it up, and our new data must match by definition.
-->
<!--
TITLE: "Assessing self-discrepancies by interview: reliability and validity of interview schedules trialed with healthy elderly individuals and pulmonary rehabilitation patients"
-->
	<xsl:template mode="document-properties" match="TITLE">
		<field name="title" type="text" operation="set">
			<text><xsl:value-of select="."/></text>
		</field>
	</xsl:template>

<!-- 
COLLECTION_YEAR: "2001"
Not in Murray's mapping
-->
<!--
CONF_NAME: "34th Annual Conference of the Australian Psychological Society"
Not in Murray's mapping
-->
	<xsl:template mode="document-properties" match="CONF_NAME">
		<field name="name-of-conference" type="text" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
PLACE_ACT: "Canberra, ACT"
-->
	<xsl:template mode="document-properties" match="PLACE_ACT">
		<field name="location" type="text" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
VOLUME: "27"
-->
	<xsl:template mode="document-properties" match="VOLUME">
            <field name="volume" type="text" operation="set">
              <text><xsl:value-of select="."/></text>
            </field>
           </xsl:template>
<!--
ISSUE_NUM: "2"
-->
	<xsl:template mode="document-properties" match="ISSUE_NUM">
            <field name="issue" type="text" operation="set">
              <text><xsl:value-of select="."/></text>
            </field>
         </xsl:template>
<!--
IS_CURRENT: "1"
not in Murray's mapping
property of author? i.e. current staff member?
-->
<!--
IS_CONFIDENTIAL: "0"
confidential author? document? 
<api:warnings><api:warning associated-field="confidential">Invalid Field Warning: Field confidential does not exist on a "Chapter" Publication object.</api:warning></api:warnings>
Changed now to only set the "confidential" field when the value is "true", never when "false".
-->
	<xsl:template mode="document-properties" match="IS_CONFIDENTIAL[.='1']">
            <field name="confidential" type="boolean" operation="set">
              <boolean>true</boolean>
            </field>
         </xsl:template>
<!--
ISSN: "1083-5423"
-->
	<xsl:template mode="document-properties" match="ISSN">
            <field name="issn" type="text" operation="set">
              <text><xsl:value-of select="."/></text>
              <links>
                <link type="elements/journal" href="https://{$host-and-port}/elements-api/v4.9/journals/{.}"/>
              </links>
            </field>
           </xsl:template>
<!--
YEAR_CREATED: "2000"
not in Murray's mapping
guessing publication-date
-->
	<xsl:template mode="document-properties" match="YEAR_CREATED">
		<field name="publication-date" operation="set">
			<date>
				<year><xsl:value-of select="."/></year>
			</date>
		</field>
	</xsl:template>
<!--
DESCRIPTION: 
-->

	<xsl:template mode="document-properties" match="DESCRIPTION">
            <field name="abstract" type="text" operation="set">
              <text><xsl:value-of select="."/></text>
            </field>
	</xsl:template>
<!--
KEYWORDS: "wireless;network; heterogeneous; handoff;mobile; QoS; quality of service;WLAN;wireless local area network; GPRS; general packet radio service; battery time; power consumption." - 
-->
	<xsl:template mode="document-properties" match="KEYWORDS">
		<field name="keywords" operation="add"><!-- adding rather than setting, since these may have been edited manually -->
			<keywords>
				<xsl:for-each select="tokenize(., ';\s*')">
					<keyword><xsl:value-of select="."/></keyword>
				</xsl:for-each>
			</keywords>
		</field>
	</xsl:template>
<!--
LOCATION
Values are often the locations of galleries (e.g. "La Trobe Visual Arts Centre", "Bendigo Art Gallery". but also "Torino, Italy", "Australia", etc, and also a bunch of HTTP URLs such as <http://www.realtimearts.net/article/issue66/7770>, <http://reviews.media-culture.org.au/modules.php?name=News&amp;file=article&amp;sid=2586> and similar
-->
	<xsl:template mode="document-properties" match="LOCATION">
		<field name="location" type="text" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
VERIFICATION_LVL1: "Department"
IS_VERIFIED1: "0"
IS_SIGHTED1: "0"
VERIFICATION_LVL2: "Faculty" or "All" or blank
???
Not in Murray's mapping
-->
<!--
CHAPTERS_CONT: "0"
guessing "number of CHAPTERS CONTributed" = number-of-pieces
not in Murray's mapping
ignore if value is 0
-->
	<xsl:template mode="document-properties" match="CHAPTERS_CONT[. &gt; 0]">
		<field name="number-of-pieces" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
CHAPTERS_TOTAL: "0"
data missing - ignore
-->
<!--
EDITORS: "Alison Garton" 
maps to "editors", which is a person-list like authors
But data are too messy to parse reliably:
T. Majoribanks, J. Barraket, J-S Chang, A. Dawson, M. Guillemin, M. Henry-Waring, A. Kenyon, R. Kokanovic, J. Lewis, D. Lusher, D. Nolan, P. Pyett, R. Robins, D. War, J. Wyn
R.P. Thornton & L.J. Wright
Peter Jeffrey
Filho, Walter & Carpenter, David
Ogunmokun, G., Gabbay, R., Rose, J.
Julian Meyrick, Ann Tonks and Simon Phillips
Soorae, P.S
Healy, D., Harris, A., Cockfield, S., Charlton, J. et al
*
n/a

-->
	<xsl:template mode="document-properties" match="EDITORS[not(normalize-space(.)=('n/a', '*'))]">
		<field name="editors" operation="set">
			<people>
				<person>
					<last-name><xsl:value-of select="."/></last-name>
				</person>
			</people>
		</field>
	</xsl:template>
<!--
CUSTOM_DATE: "41256", "41975", "41978", "41089" only a dozen uses; none appear to be dates. Rubbish.
-->
<!--
CITY_PUBLISHED: "Australia"
Not in Murray's mapping
guessing place-of-publication
-->
	<xsl:template mode="document-properties" match="CITY_PUBLISHED">
		<field name="place-of-publication" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
PAGE_TOTAL: "0"
28k records with page total > 0
handled as part of <pagination>, below
-->

<!--
DATE_COMPLETE: "41275" see CUSTOM_DATE - it's much the same
Rubbish - ignoring
-->
<!--
PARENT_TITLE: "The Abstracts of the 34th Annual Conference of the Australian Psychological Society"
-->
	<xsl:template mode="document-properties" match="PARENT_TITLE">
		<field name="parent-title" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
PUBLISHER_NAME: "The Australian Psychological Society Ltd"	
-->
	<xsl:template mode="document-properties" match="PUBLISHER_NAME">
		<field name="publisher" operation="set"><text><xsl:value-of select="."/></text></field>
	</xsl:template>
<!--
START_VALUE: "215" page number
END_VALUE: "233" page number
-->
	<!-- render the three pagination properties whenever the first of the three is encountered -->
	<xsl:template mode="document-properties" match="START_VALUE | END_VALUE | PAGE_TOTAL">
		<xsl:if test="not(preceding-sibling::START_VALUE | preceding-sibling::END_VALUE | preceding-sibling::PAGE_TOTAL)">
			<field name="pagination" type="pagination" operation="set">
				<pagination>
					<xsl:for-each select="../START_VALUE"><begin-page><xsl:value-of select="."/></begin-page></xsl:for-each>
					<xsl:for-each select="../END_VALUE"><end-page><xsl:value-of select="."/></end-page></xsl:for-each>
					<xsl:for-each select="../PAGE_TOTAL"><page-count><xsl:value-of select="."/></page-count></xsl:for-each>
				</pagination>
			</field>
		</xsl:if>
	</xsl:template>
<!--
LANGUAGE: "English" and various computer languages "C++", "Visual Basic version 6", "active server pages (ASP) using VB script Back end server uses SQL 2003" and even "Release 2.0". A few dozen values.
-->
	<xsl:template mode="document-properties" match="LANGUAGE">
		<field name="language" operation="set">
			<text><xsl:value-of select="."/></text>
		</field>
	</xsl:template>
<!--
PUB_NUMBER: "13"
NB in the earlier spreadsheet there were some rows with values; not with the latest
-->
	
	<!-- rendering author properties: -->
	<!--
STAFF_ID: "310817"
STUDENT_ID: "99309369"
FIRST_NAME: "Jillian"
LAST_NAME: "Francis"
FULL_NAME: "Dr Jillian  Francis"
PUBPER_PK: "100002089"
	-->
	<xsl:template mode="author-properties" match="FIRST_NAME">
		<field name="first-names" operation="set">
			<text><xsl:value-of select="."/></text>
		</field>
	</xsl:template>
	
	<xsl:template mode="author-properties" match="LAST_NAME">
		<field name="last-name" operation="set">
			<text><xsl:value-of select="."/></text>
		</field>
	</xsl:template>

</xsl:stylesheet>

