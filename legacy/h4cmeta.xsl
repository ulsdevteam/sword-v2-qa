<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:meta="https://hykucommons.org/schema/metadata"  exclude-result-prefixes="meta">
	<xsl:template match="/">
		<metadata>
			<xsl:for-each select="//meta:*">
				<xsl:element name="{local-name()}">
					<xsl:value-of select="." />
				</xsl:element>
			</xsl:for-each>
		</metadata>
	</xsl:template>
</xsl:stylesheet>
