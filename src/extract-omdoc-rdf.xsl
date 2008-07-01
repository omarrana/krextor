<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
    *  Gordan Ristovski
    *  Andrei Ioniţă
    *  Jacobs University Bremen
    *
    *   Krextor is free software; you can redistribute it and/or
    * 	modify it under the terms of the GNU Lesser General Public
    * 	License as published by the Free Software Foundation; either
    * 	version 2 of the License, or (at your option) any later version.
    *
    * 	This program is distributed in the hope that it will be useful,
    * 	but WITHOUT ANY WARRANTY; without even the implied warranty of
    * 	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    * 	Lesser General Public License for more details.
    *
    * 	You should have received a copy of the GNU Lesser General Public
    * 	License along with this library; if not, write to the
    * 	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
    * 	Boston, MA 02111-1307, USA.
    * 
-->

<!DOCTYPE xsl:stylesheet [
    <!ENTITY odo "http://www.omdoc.org/ontology#">
    <!ENTITY dc "http://purl.org/dc/elements/1.1/">
]>

<!--
	This stylesheet extracts RDF from OMDoc documents.

	See https://svn.omdoc.org/repos/omdoc/trunk/owl for the corresponding ontology.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.mathweb.org/omdoc"
    xmlns:omdoc="http://www.mathweb.org/omdoc"
    xmlns:om="http://www.openmath.org/OpenMath"
    exclude-result-prefixes="omdoc om"
    version="2.0">

    <!-- Specifies whether MMT-style URLs (OMDoc 1.3) should be generated -->
    <xsl:param name="mmt" select="false()"/>

    <!-- Intercept auto-generation of fragment URIs from xml:ids, as this 
         should not always be done for OMDoc -->
    <xsl:param name="autogenerate-fragment-uris" select="false()"/>

    <xsl:param name="use-root-xmlid" select="false()"/>

    <xsl:include href="util-openmath-symbols.xsl"/>
	
    <xsl:template name="create-omdoc-resource">
	<xsl:param name="related-via-property"/>
	<xsl:param name="type"/>
	<xsl:param name="base-uri" tunnel="yes"/>
	<xsl:param name="mmt" select="$mmt and @name"/>
	<xsl:param name="use-document-uri" select="not($use-root-xmlid) and self::node() = /"/>
	<!-- Check if we can generate a URI for the current element -->
	<xsl:if test="$mmt or $use-document-uri or @xml:id">
	    <xsl:call-template name="create-resource">
		<!-- If we are not on top level, manipulate the base URI,
		     either in MMT or in OMDoc 1.2 style -->
		<xsl:with-param name="base-uri" select="if ($mmt and @name)
		    then concat($base-uri, '/', @name)
		    else $base-uri" tunnel="yes"/>
		<xsl:with-param name="autogenerate-fragment-uri" select="not($mmt) and not($use-document-uri)"/>
		<xsl:with-param name="related-via-property" select="$related-via-property"/>
		<xsl:with-param name="type" select="$type"/>
	    </xsl:call-template>
	</xsl:if>
    </xsl:template>
		
	<xsl:template match="metadata/*">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="concat(namespace-uri(), local-name())"/>
		</xsl:call-template>
	</xsl:template>
	
    <xsl:template match="theory">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="type" select="'&odo;Theory'"/>
	</xsl:call-template>

	<!-- TODO make this the home theory of any statement-level child
	and any subtheory, which is not in an XIncluded or ref-included document
	Probably use a separate mode for that, to be able to match e.g.
	match="definition" mode="child" and generate containsDefinition from that,
	instead of a generic contains relationship. -->
    </xsl:template>

    <xsl:template match="@meta[parent::theory]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;metaTheory'"/>
	</xsl:call-template>
    </xsl:template>

    <!-- A plain OMDoc 1.2 import without morphism -->
    <xsl:template match="imports[not(*)]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;imports'"/>
	    <xsl:with-param name="object" select="@from"/>
	</xsl:call-template>
    </xsl:template>

    <!-- An MMT (OMDoc 1.3) import -->
    <xsl:template match="import">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="type" select="'&odo;Import'"/>
	</xsl:call-template>
    </xsl:template>    

    <xsl:template match="@from[parent::imports]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;imports'"/>
	</xsl:call-template>
    </xsl:template>
	
	
	<xsl:template match="@verbalizes[parent::omtext]">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="list" select="true()"/>
			<xsl:with-param name="property" select="'&odo;verbalizes'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="@logic[parent::FMP]">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="'&odo;logic'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="@xml:lang[parent::CMP]">
		<xsl:call-template name="add-literal-property">
			<xsl:with-param name="property" select="'&dc;language'"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="om:OMOBJ//om:OMS">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;usesSymbol'"/>
			<!-- use the innermost cdbase attribute. At least the OMOBJ must have a cdbase attribute,
				or otherwise the default is assumed -->
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>

    <!-- TODO: MMT imports: add Theory-hasImport-Import-importsFrom-Theory -->

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <xsl:template match="symbol[not(@role)]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Symbol'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <!-- TODO adapt to further progress of the MMT (OMDoc 1.3) specification -->
    <xsl:template match="symbol[@role='axiom']|axiom">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Axiom'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="definition[@name or @xml:id]">
	<xsl:call-template name="create-omdoc-resource">
	    <xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Definition'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="@for[parent::definition]">
	<xsl:call-template name="add-uri-property">
	    <xsl:with-param name="property" select="'&odo;defines'"/>
	</xsl:call-template>
    </xsl:template>
	
    <xsl:template match="alternative">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;AlternativeDefinition'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>


	<!--Gordan: Potential problem, now that I have the type in omtext... will resolve later, after I finish with the property-->
    <xsl:template match="type[not(parent::symbol)]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;TypeAssertion'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[not(@type)]">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Assertion'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='theorem']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Theorem'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='lemma']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Lemma'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='corollary']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Corollary'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='proposition']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Proposition'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='conjecture']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Conjecture'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='false-conjecture']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;FormalConjecture'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='obligation']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Obligation'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='postulate']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Postulate'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='formula']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Formula'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='assumption']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Assumption'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="assertion[@type='rule']">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Rule'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

    <xsl:template match="example">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	    <xsl:with-param name="type" select="'&odo;Example'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>

	<!--TODO: modeling of for attribute in proof, I dont think it can be solved now, since it is similar to the phrase problem-->
    <xsl:template match="proof">
	<xsl:call-template name="create-omdoc-resource">
		<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
	   	<xsl:with-param name="type" select="'&odo;Proof'"/>
		<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
	</xsl:call-template>
    </xsl:template>
	
	<!-- Gordan: extended extraction for the extended ontology -->
	
	<xsl:template match="omtext[@type='axiom']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Axiom'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='definition']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Definition'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='example']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Example'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='proof']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Proof'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type = 'assertion']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Assertion'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='corollary']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Corollary'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='conjecture']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Conjecture'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='falseconjecture']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;FalseConjecture'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='formula']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Formula'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='lemma']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Lemma'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='postulate']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Postulate'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='proposition']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Proposition'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='theorem']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Theorem'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<!--TODO Assumption may have the inductive attribute-->
	<xsl:template match="omtext[@type='assumption']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Assumption'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='obligation']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Obligation'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[@type='rule']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Rule'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="omtext[not(@type) and not(parent::proof)]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="if (parent::proof) then '&odo;hasStep' else '&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Statement'"/>
			<!--AND ALSO ADD FORMALITY DEGREE AS SOON AS CHRISTOPH FINISHES IT-->
		</xsl:call-template>>
	</xsl:template>
	
	<!--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!-->
	
	<xsl:template match="omtext[not(@type) and parent::proof]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;InformalProofStep'"/>
		</xsl:call-template>>
	</xsl:template>
	
	<xsl:template match="CMP">
		
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasProperty'"/>
			<xsl:with-param name="type" select="'&odo;InformalProperty'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="FMP">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasProperty'"/>
			<xsl:with-param name="type" select="'&odo;FormalProperty'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="assumption[parent::FMP]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;assumes'"/>
			<xsl:with-param name="type" select="'&odo;Assumption'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="conclusion[parent::FMP]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;concludes'"/>
			<xsl:with-param name="type" select="'&odo;Conclusion'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="CMP//term[@role='definiendum']">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;defines'"/>
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="CMP//term[@role='definiens']">
		<xsl:call-template name="add-uri-property">
			<xsl:with-param name="property" select="'&odo;usesSymbol'"/>
			<xsl:with-param name="object" select="om:symbol-uri((ancestor-or-self::om:*/@cdbase)[last()], @cd, @name)"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[@type='conclusion']" mode="mode2">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;DerivedConclusion'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[@type='gap']">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Gap'"/>
		</xsl:call-template>
	</xsl:template>
	
	<xsl:template match="derive[not(@type='conclusion') and not(@type='gap')]">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;DerivationStep'"/>
		</xsl:call-template>
	</xsl:template> 
	
	<xsl:template match="hypothesis">
		<xsl:call-template name="create-omdoc-resource">
			<xsl:with-param name="related-via-property" select="'&odo;hasPart'"/>
			<xsl:with-param name="type" select="'&odo;Hypothesis'"/>
		</xsl:call-template>
	</xsl:template>
	
</xsl:stylesheet>
