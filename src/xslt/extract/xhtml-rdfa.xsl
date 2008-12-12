<?xml version="1.0" encoding="UTF-8"?>

<!--
    *  Copyright (C) 2008
    *  Christoph Lange
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

<!DOCTYPE stylesheet [
    <!ENTITY rdf "http://www.w3.org/1999/02/22-rdf-syntax-ns#">
]>

<!--
    This stylesheet extracts RDF from XHTML documents annotated with RDFa.
-->
<stylesheet xmlns="http://www.w3.org/1999/XSL/Transform" 
    xpath-default-namespace="http://www.w3.org/1999/xhtml"
    xmlns:krextor="http://kwarc.info/projects/krextor"
    xmlns:xd="http://www.pnp-software.com/XSLTdoc"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="2.0">

    <import href="util/rdfa.xsl"/>
    <import href="util/openmath/verb.xsl"/>

    <xd:doc type="stylesheet">
	<xd:short>Extraction module for <a href="http://www.w3.org/TR/rdfa-primer/">XHTML+RDFa</a>, a language that allows for embedding RDF into XHTML</xd:short>
	<xd:author>Christoph Lange</xd:author>
	<xd:copyright>Christoph Lange, 2008</xd:copyright>
	<xd:svnId>$Id$</xd:svnId>
    </xd:doc>
    
    <strip-space elements="*"/>

    <param name="autogenerate-fragment-uris" select="()"/>

    <xd:doc>Use the base URI from the <code>base</code> element in the <code>head</code>, if present</xd:doc>
    <template match="/">
	<variable name="base-uri" select="/html/head/base[1]/@href"/>
	<choose>
	    <when test="$base-uri">
		<apply-imports>
		    <with-param name="krextor:base-uri" select="$base-uri" tunnel="yes"/>
		</apply-imports>
	    </when>
	    <otherwise>
		<apply-imports/>
	    </otherwise>
	</choose>
    </template>

    <function name="krextor:default-curie-namespace">
	<param name="focus"/>
	<sequence select="'http://www.w3.org/1999/xhtml/vocab#'"/>
    </function>

    <xd:doc>Translates the reserved XHTML link types (as specified in the <a href="http://www.w3.org/TR/rdfa-syntax/#relValues">Metainformation Attributes Module</a>) to URIs</xd:doc>
    <template match="krextor:curie" mode="krextor:resolve-prefixless-curie" as="xs:string">
	<sequence select="if (. = (
		'alternate',
		'appendix',
		'bookmark',
		'cite',
		'chapter',
		'contents',
		'copyright',
		'first',
		'glossary',
		'help',
		'icon',
		'index',
		'last',
		'license',
		'meta',
		'next',
		'p3pv1',
		'prev',
		'role',
		'section',
		'stylesheet',
		'subsection',
		'start',
		'top',
		'up'
	    )) then concat('http://www.w3.org/1999/xhtml/vocab#', .)
	    else ''"/>
    </template>

    <!-- FIXME restrict to those elements where @about is actually allowed -->
    <!-- process any element with RDFa attributes -->
    <template match="*[@resource or @src or @about or @href or @typeof or @rel or @rev or @property]">
	<param name="tunneled-property" as="xs:string*" tunnel="yes"/>
	<param name="tunneled-inverse" tunnel="yes"/>

	<message>ME</message>
	<message select="."/>

	<variable name="type" select="krextor:curies-to-uris(., @typeof)"/>
	<variable name="process-next" select="
	    (@* except 
		((if (exists(@about|@src|@typeof|@resource)) then () else (@rel|@rev))
		|(if (@rel|rev) then (@resource|@href) else ())
		|@src|@about|@typeof))
	    |(if (@property or @resource or ((@rel or @rev) and not(@href)))
		then () else *)"/>
	<variable name="about-given" select="@about or (self::head or self::body)"/>
	<variable name="new-subject" as="xs:string*" select="
	    if (not(@rel or @rev)) then
		if ($about-given) then string(@about)
		else if (@src) then @src
		else if (@resource) then @resource
		else if (@href) then @href
		else ()
	    else
		if ($about-given) then string(@about)
		else if (@src) then @src
		else ()"/>
	<variable name="blank-node-id" select="if (exists($new-subject)) then krextor:safe-curie-to-bnode-id($new-subject) else ()"/>
	<variable name="related-via-properties" select="(
	    if (not(exists(@about|@src|@typeof))) then krextor:curies-to-uris(., @rel) else (),
	    if (exists($tunneled-property) and not($tunneled-inverse)) then $tunneled-property else ())"/>
	<variable name="related-via-inverse-properties" select="(
	    if (not(exists(@about|@src|@typeof))) then krextor:curies-to-uris(., @rev) else (),
	    if (exists($tunneled-property) and $tunneled-inverse) then $tunneled-property else ())"/>

	<message>SUBJECT</message>
	<message select="trace($new-subject, 'subject')"/>

	<message>TYPE</message>
	<message select="$type"/>

	<message>RELATED VIA</message>
	<message>PROPERTIES</message>
	<message select="$related-via-properties"/>
	<message>INVERSE PROPERTIES</message>
	<message select="$related-via-inverse-properties"/>

	<variable name="no-subject" select="trace(not(exists($new-subject))
		and not(@resource|@rel|@rev), 'no subject!')"/>
	<variable name="blank" select="$blank-node-id
	    or $no-subject
	    or (@typeof and not($about-given or (@resource and not(@rel or @rev))))"/>

	<message>BLANK</message>
	<message select="$blank"/>

	<choose>
	    <when test="not(exists($tunneled-property)) and not(exists($new-subject)) and not(@typeof)">
	    <!--
	    <when test="not(exists($new-subject)) and not(@typeof)">
	    -->
		<message>ADDING PROPERTY</message>
		<message>FOR</message>
		<message select="."/>
		<apply-templates select="trace(@property|@rel|@rev, 'prop')"/>
	    </when>
	    <when test="$blank">
		<message>CREATING BNODE</message>
		<message select="$blank-node-id"/>
		<message>NEXT</message>
		<message select="$process-next"/>
		<call-template name="krextor:create-resource">
		    <with-param name="this-blank-node-id" select="$blank-node-id"/>
		    <with-param name="blank-node" select="true()"/>
		    <with-param name="type" select="$type"/>
		    <with-param name="related-via-properties" select="$related-via-properties"/>
		    <with-param name="related-via-inverse-properties" select="$related-via-inverse-properties"/>
		    <!-- FIXME actually, this is:
			@content, or ...
			@... (some other RDFa properties) -->
		    <with-param name="process-next" select="$process-next"/>
		</call-template>
	    </when>
	    <otherwise>
		<message>CREATING RESOURCE</message>
		<message select="$new-subject"/>
		<message>NEXT</message>
		<message select="$process-next"/>
		<call-template name="krextor:create-resource">
		    <with-param name="subject" select="if ($new-subject) then krextor:safe-curie-to-uri(., $new-subject) else ()"/>
		    <with-param name="blank-node" select="$no-subject"/>
		    <with-param name="type" select="$type"/>
		    <with-param name="related-via-properties" select="$related-via-properties"/>
		    <with-param name="related-via-inverse-properties" select="$related-via-inverse-properties"/>
		    <!-- FIXME actually, this is:
			@content, or ...
			@... (some other RDFa properties) -->
		    <with-param name="process-next" select="$process-next"/>
		</call-template>
	    </otherwise>
	</choose>
    </template>

    <!-- FIXME restrict to those elements where @about is actually allowed -->
    <!--
    <template match="*[not(@resource or @src or @about or @typeof or @rel or @rev)]">
	<apply-templates select="@property|@href|*"/>
    </template>
    -->
</stylesheet>
