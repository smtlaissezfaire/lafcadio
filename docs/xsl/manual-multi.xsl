<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="/Users/francis/Tech/docbook-xsl-1.69.1/html/chunk.xsl"/>

<xsl:template match="sect1[@role = 'NotInToc']"  mode="toc" />
<xsl:template match="sect2[@role = 'NotInToc']"  mode="toc" />
<xsl:param name="html.stylesheet" select="'../manual.css'"/>
<xsl:param name="use.id.as.filename" select="1" />
</xsl:stylesheet>
