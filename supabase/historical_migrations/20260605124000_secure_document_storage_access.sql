-- Align private Storage object access with document_attachments entity RLS.

CREATE OR REPLACE FUNCTION public.can_access_document_path(p_file_path TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM public.document_attachments document
        WHERE document.file_path = p_file_path
          AND (
              document.uploaded_by = auth.uid()
              OR public.can_access_document_entity(
                  document.entity_type,
                  document.entity_id
              )
          )
    )
$$;

DROP POLICY IF EXISTS "users_manage_own_documents" ON storage.objects;
DROP POLICY IF EXISTS "admin_access_all_documents" ON storage.objects;
DROP POLICY IF EXISTS "erp_documents_read" ON storage.objects;
DROP POLICY IF EXISTS "erp_documents_insert" ON storage.objects;
DROP POLICY IF EXISTS "erp_documents_update" ON storage.objects;
DROP POLICY IF EXISTS "erp_documents_delete" ON storage.objects;

CREATE POLICY "erp_documents_read"
ON storage.objects
FOR SELECT TO authenticated
USING (
    bucket_id = 'erp-documents'
    AND (
        owner = auth.uid()
        OR public.can_access_document_path(name)
    )
);

CREATE POLICY "erp_documents_insert"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'erp-documents'
    AND owner = auth.uid()
);

CREATE POLICY "erp_documents_update"
ON storage.objects
FOR UPDATE TO authenticated
USING (
    bucket_id = 'erp-documents'
    AND (owner = auth.uid() OR public.is_admin())
)
WITH CHECK (
    bucket_id = 'erp-documents'
    AND (owner = auth.uid() OR public.is_admin())
);

CREATE POLICY "erp_documents_delete"
ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'erp-documents'
    AND (owner = auth.uid() OR public.is_admin())
);
