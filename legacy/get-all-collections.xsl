<xsl:stylesheet version="1.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:app="http://www.w3.org/2007/app" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" />
	<xsl:template match="/">
		<xsl:for-each select="/app:service/app:workspace/app:collection/@href">
			<xsl:value-of select="substring-after(., '/collections/')" /><xsl:text>&#10;</xsl:text>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
