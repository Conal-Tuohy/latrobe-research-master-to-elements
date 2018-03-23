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
    xmlns:cx="http://xmlcalabash.com/ns/extensions"
	name="upload-test">
	<p:import href="library.xpl"/>
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<p:input port="parameters" kind="parameter"/>
    <p:option name="input-folder" required="true"/>
    <p:option name="log-folder" required="true"/>
    <p:option name="username" required="true"/>
    <p:option name="password" required="true"/>

	<file:mkdir fail-on-error="false">
        <p:with-option name="href" select="$log-folder"/>
    </file:mkdir>

    <p:directory-list name="input-files">
        <p:with-option name="path" select="$input-folder"/>
    </p:directory-list>
    <p:for-each name="elements-patch">
        <p:iteration-source select="/c:directory/c:file"/>
        <p:variable name="filename" select="c:file/@name"/>
        <p:www-form-urldecode>
            <p:with-option name="value" select="concat('url=', substring-before($filename, '.xml'))"/>
        </p:www-form-urldecode>
        <p:group>
            <p:variable name="elements-uri" select="/c:param-set/c:param/@value"/>
            <cx:message>
                <p:with-option name="message" select="concat('uploading ', $elements-uri, ' ...')"/>
            </cx:message>
	        <p:load>
		        <p:with-option name="href" select="
			        concat(
				        $input-folder,
                        if (ends-with($input-folder, '/')) then '' else '/',
                        encode-for-uri($filename)
			        )
		        "/>
	        </p:load>
	        <p:xslt name="create-http-request">
		        <p:with-param name="href" select="$elements-uri"/>
                <p:with-param name="username" select="$username"/>
                <p:with-param name="password" select="$password"/>
		        <p:input port="stylesheet">
			        <p:inline>
				        <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns="http://www.symplectic.co.uk/publications/api">
					        <xsl:param name="href"/>
                            <xsl:param name="username"/>
                            <xsl:param name="password"/>
					        <xsl:template match="/*">
						        <c:request method="PATCH" detailed="true" href="{$href}" password="{$password}" username="{$username}" auth-method="Basic" send-authorization="true">
							        <c:header name="Content-Type" value="text/xml"/>
							        <c:body content-type="text/xml">
								        <xsl:copy-of select="."/>
							        </c:body>
						        </c:request>
					        </xsl:template>
				        </xsl:stylesheet>
			        </p:inline>
		        </p:input>
	        </p:xslt>
	        <p:http-request name="upload"/>
            <p:exec command="sleep" args="0.5" result-is-xml="false"/>
            <p:sink/>
            <!-- log the response -->
	        <p:store xmlns:cx="http://xmlcalabash.com/ns/extensions" cx:decode="true" indent="true">
                <p:with-option name="href" select="
                    concat(
                        $log-folder,
                        if (ends-with($log-folder, '/')) then '' else '/',
                        encode-for-uri($filename)
                    )
                "/>
		        <p:input port="source" select="/c:response/c:body">
			        <p:pipe step="upload" port="result"/>
		        </p:input>
	        </p:store>
            <!--
            <p:store xmlns:cx="http://xmlcalabash.com/ns/extensions" cx:decode="true" indent="true"
                href="/tmp/request.xml">
                <p:input port="source"><p:pipe step="create-http-request" port="result"/></p:input>
            </p:store>
            -->
        </p:group>
    </p:for-each>
	
</p:declare-step>
