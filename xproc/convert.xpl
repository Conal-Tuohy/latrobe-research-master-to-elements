<p:declare-step version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:lib="http://conaltuohy.com/" 
	xmlns:pxp="http://exproc.org/proposed/steps"
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:ss="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
	xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
	xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
	xmlns:mv="urn:schemas-microsoft-com:mac:vml"
	xmlns:elements="http://www.symplectic.co.uk/publications/api"
	name="convert-research-master-to-symplectics"
    xpath-version="2.0"
>
	<p:import href="library.xpl"/>
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:option name="elements-spreadsheet" required="true"/>
	<p:option name="research-master-spreadsheet" required="true"/>
	<p:option name="output-folder" required="true"/>
    <p:option name="host" required="true"/>
	
	<p:input port="parameters" kind="parameter"/>
	
	<file:mkdir fail-on-error="false">
        <p:with-option name="href" select="$output-folder"/>
    </file:mkdir>
		
	<lib:load-spreadsheet name="stub-records-spreadsheet">
        <p:with-option name="href" select="$elements-spreadsheet"/>
    </lib:load-spreadsheet>
	<lib:transform 
		name="simple-stub-records" 
		xslt="../xslt/convert-spreadsheet-to-simple-xml.xsl"/>

	<lib:load-spreadsheet name="research-master-spreadsheet">
		<p:with-option name="href" select="$research-master-spreadsheet"/>
    </lib:load-spreadsheet>
	<lib:transform 
		name="simple-research-master" 
		xslt="../xslt/convert-spreadsheet-to-simple-xml.xsl"/>
		
	<p:wrap-sequence 
		name="wrapped"
		wrapper="data">
		<p:input port="source">
			<p:pipe step="simple-stub-records" port="result"/>
			<p:pipe step="simple-research-master" port="result"/>
		</p:input>
	</p:wrap-sequence>
	
    <p:xslt name="symplectics">
        <p:input port="stylesheet">
            <p:document href="../xslt/convert-simple-xml-to-symplectics.xsl"/>
        </p:input>
        <p:with-param name="host" select="$host"/>
    </p:xslt>

		
	<p:for-each name="symplectic-record">
		<p:iteration-source select="/data/patch"/>
		<p:variable name="uri" select="/patch/@uri"/>
		<p:unwrap match="/patch"/>
		<p:store indent="true">
			<p:with-option name="href" select="
				concat(
					$output-folder,
                    if (ends-with($output-folder, '/')) then '' else '/',
					encode-for-uri(encode-for-uri($uri)),
					'.xml'
				)
			"/>
		</p:store>
	</p:for-each>

    <!-- store intermediate stage documents (for debugging) -->
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/symplectics.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="symplectics" port="result"/>
		</p:input>
	</p:store>
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/research-master.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="simple-research-master" port="result"/>
		</p:input>
	</p:store>
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/research-master-spreadsheet.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="research-master-spreadsheet" port="result"/>
		</p:input>
	</p:store>	
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/stub-records.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="simple-stub-records" port="result"/>
		</p:input>
	</p:store>
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/stub-records-spreadsheet.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="stub-records-spreadsheet" port="result"/>
		</p:input>
	</p:store>
	<p:store indent="true">
		<p:with-option name="href" select="
			concat(
				$output-folder,
                if (ends-with($output-folder, '/')) then '' else '/',
                'debug/wrapped.xml'
			)
		"/>
		<p:input port="source">
			<p:pipe step="wrapped" port="result"/>
		</p:input>
	</p:store>
	
</p:declare-step>
