.. These are examples of badges you might want to add to your README:
   please update the URLs accordingly

    .. image:: https://api.cirrus-ci.com/github/<USER>/osc-physrisk-metadata.svg?branch=main
        :alt: Built Status
        :target: https://cirrus-ci.com/github/<USER>/osc-physrisk-metadata
    .. image:: https://readthedocs.org/projects/osc-physrisk-metadata/badge/?version=latest
        :alt: ReadTheDocs
        :target: https://osc-physrisk-metadata.readthedocs.io/en/stable/
    .. image:: https://img.shields.io/coveralls/github/<USER>/osc-physrisk-metadata/main.svg
        :alt: Coveralls
        :target: https://coveralls.io/r/<USER>/osc-physrisk-metadata
    .. image:: https://img.shields.io/pypi/v/osc-physrisk-metadata.svg
        :alt: PyPI-Server
        :target: https://pypi.org/project/osc-physrisk-metadata/
    .. image:: https://img.shields.io/conda/vn/conda-forge/osc-physrisk-metadata.svg
        :alt: Conda-Forge
        :target: https://anaconda.org/conda-forge/osc-physrisk-metadata
    .. image:: https://pepy.tech/badge/osc-physrisk-metadata/month
        :alt: Monthly Downloads
        :target: https://pepy.tech/project/osc-physrisk-metadata
    .. image:: https://img.shields.io/twitter/url/http/shields.io.svg?style=social&label=Twitter
        :alt: Twitter
        :target: https://twitter.com/osc-physrisk-metadata

.. image:: https://img.shields.io/badge/-PyScaffold-005CA0?logo=pyscaffold
    :alt: Project generated with PyScaffold
    :target: https://pyscaffold.org/

|

=====================
osc-physrisk-metadata
=====================

    OS-Climate Physical Risk and Resilience Metadata Project

Contains Physical Risk & Resilience (PRR) -related metadata, standardization, and schema information for a variety of supporting technologies and formats, including CSV, JSON, and SQL.

# Goals
Minimize the effort required to perform common PRR data-related and coding-related tasks, including:
* Storing and retrieving lookup values from a data store.
* Providing placeholders for common metadata, spatial and temporal values (since PRR activities and data are inherently geospatial)
* Validating data sets against CSV and tabular database schemas
* Improving data consistency across systems
* Making PRR-related taxonomies and logical models more consistent
* Reducing scaffolding efforts for building a datastore-driven system that leverages or exports PRR data
* Improving system and data interoperability
* Reducing the Total Cost of Ownership (TCO) of software stacks built using PRR functionality and data, by reducing the time and effort required by developers, testers, scientists, and integrators.

# Design Notes
## We Favour Reducing People, Computing and Querying Costs over Reducing Storage Costs
To achieve the last goal, we deliberately denormalize certain data structures, even when it results in duplication of columnar data or presence of data in schemas that could be extracted to lookup / dimension tables. This is 
a design trade-off that the cost of extra storage is minute compared to the improved performance of reduced joins for common query activities (such as spatial or temporal lookups) and reduced developer / tester burden.

## We Use Standard Columns
We anticipate common data and software development needs, such as requiring names and descriptions, handling data-level translations, storing tags, and tracking who created modified or deleted values. We have therefore adopted a standard column schema which is present in most schemas. 
These are prefixed with "core_" making it easier to adopt into existing systems by avoiding naming clashes. Knowing these columns are present makes it easier for software developers, testers, and data scientists to build utilities and applications. 
Many of them are nullable so if they aren't useful to you (yet?), just leave them empty.

## We Try to Balance Flexibility with Standardization
Each application use case is very different and we cannot possible create a schema that satisfies every one. Even the standards we try to support, 
such as Uber H3, country codes, and industry codes, often require picking amongst half-a-dozen (often very similar) candidates. 

So, our table schemas usually include at least one json column which is a highly flexible storage location. We also try to add useful placeholders fields, which are nullable. 
It is up to the implementor to ensure that values stored inside those fields are properly validated and maintained, according to their own business rules. 

Hopefully this approach is a practical and sane balance between "no standard at all" versus an inflexible schema that is impossible to adopt and evolve.

## We Use Unique Identifiers/GUIDs for Data Interoperability
Schemas and ID properties are almost always GUIDs (except in a few application-specific data sets such as "User" or "Tenant"). The idea is to facilitate
sharing and integration of data sets and functionality, while minimizing risk of clashes with existing ID structures (although GUIDs can still have clashes, it's unlikely). 
This should make it easier to import and export data sets and combine data from multiple parties.

In order to promote consistency, our design also recommends the use of standardized uuid/GUID identifiers for common data-related semantics including handling
"Any" result, "None", or "Unknown". These special values should conform to version/variant rules of GUIDs, they should be easy to tell apart, with standard prefixes, 
and the tail of the GUID encodes meaning in hex such as "any", "none", "unk". The standard Guids should be compatible with a wide variety of technologies and languages including C#, Python, Postgres, and RESTful APIs.

When passed as argument, or in CSV file:
* Empty: 00000000-0000-0000-0000-000000000000
* Undefined/Missing: NULL

When stored in database:
* Undefined/Missing: NULL
* Any: aaaaaaaa-aaaa-4aaa-8aaa-616e79000000
* None: bbbbbbbb-bbbb-4bbb-8bbb-6e6f6e650000
* Unknown: ffffffff-ffff-4fff-8fff-756e6b000000

If these are used, it should be easy for any developer or data scientist to quickly query an ID lookup in a data set for "Any" record (aaaaaaaa-aaaa-4aaa-8aaa-616e79000000) or for something marked as Unknown (ffffffff-ffff-4fff-8fff-756e6b000000).

## We Expect Data to be Translated
Climate change is global, but cultures and languages may be local. So, we anticipate that application developers or data scientists may well want to translate their data sets into multiple languages for sharing or reporting. To help, our schemas can store data-level translation values. Without such placeholders, it is nearly impossible to translate at the data row level since it will be hard to "match" different values to each other once they are translated.

Our common columns include a "core_culture" field as well as a (nullable) "core_translated_from_id" field. If you only need to support one language, set the default culture (ex "en", "es") and leave "core_translated_from_id" null. 
If you need to support more than one language, start by inserting the "default language" row, then use its "core_id" as the value you place in the second language's "core_translated_from_id" field, and put the appropriate ISO culture code in the "core_culture" field. You can now search for this row using its own core_id, or by finding the default language id and then finding "core_translated_from_id" values that match, or by looking up the "core_culture" value that matches the langauge you want.


.. _pyscaffold-notes:

Note
====

This project has been set up using PyScaffold 4.5. For details and usage
information on PyScaffold see https://pyscaffold.org/.
