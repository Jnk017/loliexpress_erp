BEGIN READ ONLY;
WITH relations AS (
  SELECT c.*, n.nspname, n.nspname || '.' || c.relname AS object
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE n.nspname IN ('public','storage','auth') AND c.relkind IN ('r','p','v','m','S')
), routines AS (
  SELECT p.*, n.nspname,
         n.nspname || '.' || p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')' AS object
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('public','storage','auth') AND p.prokind IN ('f','p')
), inventory(kind, object, detail) AS (
  SELECT 'relation', object, jsonb_build_object('kind',relkind,'owner',pg_get_userbyid(relowner),'rls',relrowsecurity,'force_rls',relforcerowsecurity,'options',reloptions) FROM relations
  UNION ALL SELECT 'column', r.object || '.' || a.attname, jsonb_build_object('position',a.attnum,'type',format_type(a.atttypid,a.atttypmod),'required',a.attnotnull,'default_hash',md5(pg_get_expr(d.adbin,d.adrelid)),'identity',a.attidentity,'generated',a.attgenerated)
  FROM relations r JOIN pg_attribute a ON a.attrelid=r.oid LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum
  WHERE a.attnum>0 AND NOT a.attisdropped
  UNION ALL SELECT 'constraint',r.object || '.' || conname, jsonb_build_object('kind',contype,'hash',md5(pg_get_constraintdef(c.oid)),'validated',convalidated)
  FROM relations r JOIN pg_constraint c ON c.conrelid=r.oid
  UNION ALL SELECT 'index',r.object || '.' || i.relname, jsonb_build_object('hash',md5(pg_get_indexdef(i.oid)),'valid',x.indisvalid)
  FROM relations r JOIN pg_index x ON x.indrelid=r.oid JOIN pg_class i ON i.oid=x.indexrelid
  UNION ALL SELECT 'view',object,to_jsonb(md5(pg_get_viewdef(oid))) FROM relations WHERE relkind IN ('v','m')
  UNION ALL SELECT 'sequence',schemaname || '.' || sequencename,jsonb_build_object('type',data_type::text,'start',start_value,'min',min_value,'max',max_value,'increment',increment_by,'cycle',cycle,'cache',cache_size) FROM pg_sequences WHERE schemaname IN ('public','storage','auth')
  UNION ALL SELECT 'type',n.nspname || '.' || t.typname,jsonb_build_object('kind',t.typtype,'enum',(SELECT jsonb_agg(enumlabel ORDER BY enumsortorder) FROM pg_enum WHERE enumtypid=t.oid))
  FROM pg_type t JOIN pg_namespace n ON n.oid=t.typnamespace WHERE n.nspname IN ('public','storage','auth') AND t.typtype IN ('e','d','r','m')
  UNION ALL SELECT 'routine',object,jsonb_build_object('hash',md5(pg_get_functiondef(oid)),'definer',prosecdef,'owner',pg_get_userbyid(proowner),'search_path',(SELECT split_part(v,'=',2) FROM unnest(proconfig) v WHERE v LIKE 'search_path=%'),'authenticated',has_function_privilege('authenticated',oid,'EXECUTE'),'anon',has_function_privilege('anon',oid,'EXECUTE'),'acl',proacl::text) FROM routines
  UNION ALL SELECT 'trigger',r.object || '.' || tgname,jsonb_build_object('hash',md5(pg_get_triggerdef(t.oid)),'mode',tgenabled)
  FROM relations r JOIN pg_trigger t ON t.tgrelid=r.oid WHERE NOT tgisinternal
  UNION ALL SELECT 'policy',schemaname || '.' || tablename || '.' || policyname,jsonb_build_object('roles',roles,'command',cmd,'mode',permissive,'using_hash',md5(qual),'check_hash',md5(with_check)) FROM pg_policies WHERE schemaname IN ('public','storage','auth')
  UNION ALL SELECT 'relation_acl',object,to_jsonb(relacl::text) FROM relations WHERE relacl IS NOT NULL
  UNION ALL SELECT 'column_acl',r.object || '.' || a.attname,to_jsonb(a.attacl::text) FROM relations r JOIN pg_attribute a ON a.attrelid=r.oid WHERE a.attnum>0 AND NOT a.attisdropped AND a.attacl IS NOT NULL
  UNION ALL SELECT 'schema_acl',nspname,to_jsonb(nspacl::text) FROM pg_namespace WHERE nspname IN ('public','storage','auth')
  UNION ALL SELECT 'default_acl',pg_get_userbyid(defaclrole) || '.' || coalesce(nspname,'*') || '.' || defaclobjtype::text,to_jsonb(defaclacl::text) FROM pg_default_acl LEFT JOIN pg_namespace ON pg_namespace.oid=defaclnamespace
  UNION ALL SELECT 'extension',extname,jsonb_build_object('version',extversion,'schema',nspname) FROM pg_extension JOIN pg_namespace ON pg_namespace.oid=extnamespace
  UNION ALL SELECT 'bucket',id,jsonb_build_object('public',public,'limit',file_size_limit,'mime',allowed_mime_types) FROM storage.buckets
  UNION ALL SELECT 'publication',pubname,jsonb_build_object('all',puballtables,'insert',pubinsert,'update',pubupdate,'delete',pubdelete,'truncate',pubtruncate) FROM pg_publication
  UNION ALL SELECT 'publication_table',pubname || '.' || schemaname || '.' || tablename,jsonb_build_object('columns',attnames,'filter_hash',md5(rowfilter)) FROM pg_publication_tables
  UNION ALL SELECT 'cron',coalesce(jobname,jobid::text),jsonb_build_object('schedule',schedule,'active',active,'command_hash',md5(command)) FROM cron.job
  UNION ALL SELECT 'vault_metadata',coalesce(name,'(unnamed)'),jsonb_build_object('present',true) FROM vault.secrets
  UNION ALL SELECT 'migration',version,jsonb_build_object('name',name) FROM supabase_migrations.schema_migrations
)
SELECT jsonb_agg(to_jsonb(inventory) ORDER BY kind,object,detail) AS inventory FROM inventory;
ROLLBACK;
