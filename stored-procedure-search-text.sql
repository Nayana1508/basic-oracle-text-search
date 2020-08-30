--Create table messages
CREATE TABLE messages
(msg_id   NUMBER,
 msg_content clob,
 msg_timestamp TIMESTAMP(6),
 CONSTRAINT msg_id_pk PRIMARY KEY (msg_id)
);

COMMENT ON COLUMN messages.msg_id IS 'Primary Key for the table.';
COMMENT ON COLUMN messages.msg_content IS 'One post (with all its replies) in JSON format.';
COMMENT ON COLUMN messages.msg_timestamp IS 'Timestamp for last update on the Post.';

--Create context index on table messages
--add default stoplist or your custom stoplist in index preference
create index MSG_ID_CTX on messages (msg_content)
indextype is ctxsys.context PARAMETERS (' stoplist CTXSYS.EMPTY_STOPLIST SYNC (ON COMMIT)');


--insert dummy data
INSERT INTO messages VALUES (1, 'this is a message', TO_TIMESTAMP('2011-03-01 15:47:07','YYYY-MM-DD HH24:Mi:SS'));
INSERT INTO messages VALUES (2, 'this is a reply to message 1', TO_TIMESTAMP('2011-03-02 15:47:28','YYYY-MM-DD HH24:Mi:SS'));
INSERT INTO messages VALUES (3, 'another cool message', TO_TIMESTAMP('2011-03-02 15:48:15','YYYY-MM-DD HH24:Mi:SS'));
INSERT INTO messages VALUES (4, 'blah blah blah Sally', TO_TIMESTAMP('2011-03-09 15:48:43','YYYY-MM-DD HH24:Mi:SS'));

---write a Stored procedure to get search count in text
CREATE OR REPLACE procedure text_search ( pi_search_text   in varchar2 , 
                                          po_count  out number

)
as
v_search_query clob;
v_search_count clob;
v_search_text  varchar2(4000);

begin
    ---replace punctuations with single wildcard character
      select regexp_replace(regexp_replace(pi_search_text,'(*[[:punct:]])', '?'), '([^?])', '\\\1')
      into v_search_text from dual;

      v_search_query :=  'SELECT /*+ first_rows(50) */
                                    m.*,
                                    score(1) as occurrence_count
                              FROM  messages m
                             WHERE  contains( msg_content, ''<query>
                                                                <textquery>
                                                                   %'||v_search_text||'%                                                                       
                                                               </textquery>
                                                                <score algorithm="count" />
                                                             </query>'', 1) > 0';
                                                             
    v_search_count := ' select nvl(sum(occurrence_count),0) from ('||v_search_query||')';
    execute immediate v_search_count into po_count ;
exception when others
then
    dbms_output.put_line('error:'||sqlerrm(sqlcode));
   raise;
end text_search;


---execute stored procedure to search any text like 'message'
SET SERVEROUTPUT ON;
DECLARE
  PO_COUNT NUMBER;  
BEGIN
  TEXT_SEARCH(PI_SEARCH_TEXT => 'message',PO_COUNT => PO_COUNT);
DBMS_OUTPUT.PUT_LINE('PO_COUNT = ' || PO_COUNT);
END;

/
