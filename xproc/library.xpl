<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:lib="http://conaltuohy.com/" 
	xmlns:pxp="http://exproc.org/proposed/steps"
	xmlns:fn="http://www.w3.org/2005/xpath-functions">
	
	<!-- loads a sheet from an XSLX spreadsheet -->
	<p:declare-step type="lib:load-spreadsheet" name="load-spreadsheet">
		<p:output port="result"/>
		<p:option name="href" required="true"/>
		<p:option name="sheet-number" select="1"/>
		<pxp:unzip name="sharedStrings" content-type="application/xml" file="xl/sharedStrings.xml">
		 	<p:with-option name="href" select="$href"/>
		 </pxp:unzip>
		 <pxp:unzip name="sheet" content-type="application/xml">
		 	<p:with-option name="href" select="$href"/>
		 	<p:with-option name="file" select="concat('xl/worksheets/sheet', $sheet-number, '.xml')"/>
		 </pxp:unzip>
		<p:wrap-sequence wrapper="wrapper">
			<p:input port="source">
				<p:pipe step="sharedStrings" port="result"/>
				<p:pipe step="sheet" port="result"/>
			</p:input>
		</p:wrap-sequence>
		<lib:transform name="normalize-spreadsheet" xslt="../xslt/inline-shared-strings.xsl">
			<p:input port="parameters">
				<p:empty/>
			</p:input>
		</lib:transform>
	</p:declare-step>

	<!-- shorthand for executing an XSLT  -->
	<p:declare-step type="lib:transform" name="transform">
		
		<p:input port="source" sequence="true"/>
		<p:output port="result" sequence="true"/>
		<p:input port="parameters" kind="parameter"/>
		
		<p:option name="xslt" required="true"/>
		
		<p:load name="load-stylesheet">
			<p:with-option name="href" select="$xslt"/>
		</p:load>
		
		<p:xslt name="execute-xslt">
			<p:input port="source">
				<p:pipe step="transform" port="source"/>
			</p:input>
			<p:input port="stylesheet">
				<p:pipe step="load-stylesheet" port="result"/>
			</p:input>
		</p:xslt>
	</p:declare-step>
	
		<!-- 
			Execute an HTTP request.
			
			Constructs an XProc http request document
			by taking "method", "uri", "username" and "password"
			parameters and substituting them into a
			template, then executes the request
		-->
	<p:declare-step type="lib:http-request" name="http-request">
		
		<p:input port="source"/>
		<p:output port="result"/>
		
		<p:option name="method" select="'get'"/>
		<p:option name="username"/>
		<p:option name="password"/>
		<p:option name="uri" required="true"/>
		<p:option name="detailed" select="'true'"/>
		<p:option name="accept" select="'text/xml'"/>
		
		<p:in-scope-names name="variables"/>
		
		<p:choose name="choose-method">
			<p:when test="($method = 'get' or $method='head' or $method='delete')">
				<p:template name="construct-request-without-body">
					<p:input port="template">
						<p:inline exclude-inline-prefixes="c">
							<c:request detailed="{$detailed}" send-authorization="true" method="{$method}" href="{$uri}" auth-method="Basic" username="{$username}" password="{$password}">
								<c:header name="Accept" value="{$accept}"/>
							</c:request>
						</p:inline>
					</p:input>
					<p:input port="source">
						<p:pipe step="http-request" port="source"/>
					</p:input>
					<p:input port="parameters">
						<p:pipe step="variables" port="result"/>
					</p:input>
				</p:template>
			</p:when>
			<p:otherwise><!-- put or post allow a message body -->
				<p:template name="construct-request-with-body">
					<p:input port="template">
						<p:inline exclude-inline-prefixes="c">
							<c:request detailed="{$detailed}" send-authorization="true" method="{$method}" href="{$uri}" auth-method="Basic" username="{$username}" password="{$password}">
								<c:header name="Accept" value="{$accept}"/>
								<c:body content-type="text/xml">{/*}</c:body>
							</c:request>
						</p:inline>
					</p:input>
					<p:input port="source">
						<p:pipe step="http-request" port="source"/>
					</p:input>
					<p:input port="parameters">
						<p:pipe step="variables" port="result"/>
					</p:input>
				</p:template>
			</p:otherwise>
		</p:choose>
		<!-- execute the request -->
		<p:http-request name="execute-request"/>
	</p:declare-step>
	
	<p:declare-step type="lib:sparql-query" name="sparql-query">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="output" select="'csv'"/>
		<p:in-scope-names name="parameters"/>
		<p:template name="generate-http-request">
			<p:input port="source">
				<p:pipe step="sparql-query" port="source"/>
			  </p:input>
			<p:input port="parameters">
				<p:pipe step="parameters" port="result"/>
			</p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="POST" href="http://localhost:8080/fuseki/dataset/query">
						<c:body content-type="application/x-www-form-urlencoded">{
							concat(
								'query=', encode-for-uri(/),
								'&amp;output=', $output
							)
						}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>
	
	<!-- store graph -->
	<p:declare-step type="lib:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-uri" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:in-scope-names name="variables"/>
		<p:template name="generate-put-request">
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="http://localhost:8080/fuseki/dataset/data?graph={$graph-uri}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
			<p:input port="parameters">
				<p:pipe step="variables" port="result"/>
			</p:input>
		</p:template>
		<!--
		<p:store>
			<p:with-option name="href" select="concat('/tmp/', $graph-uri)"/>
		</p:store>
		-->
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	

</p:library>
