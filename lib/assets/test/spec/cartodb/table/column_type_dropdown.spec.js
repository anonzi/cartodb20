
describe("Column_type_dropdown", function() {

  var view, table, container;

  beforeEach(function() {
    table = TestUtil.createTable();
    view = new cdb.admin.ColumntypeDropdown({
      position: 'position',
      horizontal_position: "left",
      tick: "left",
      template_base: "table/views/table_column_type_options"
    });
    view.dialogContainer = $('<div></div>');
    view.render();
  });

  afterEach(function() {
    $('.confirmTypeChangeDialog').remove();
  })

  it('should set the options', function() {
    view.setTable(table, 'test2')
    expect(view.table).toEqual(table);
    expect(view.column).toEqual('test2');
  });

  it('should try to disable the previous column type', function() {
    spyOn(view, '_disableColumn');
    view.setTable(table, 'test2');
    expect(view._disableColumn).toHaveBeenCalled();
  });

  describe("When the requested type change is not type safe", function() {
    it('should show the confirmation dialog when the change is destructive ', function() {
      view.setTable(table, 'test2');
      view.setColumnTypeChange('boolean');
      expect(view.confirmDialog.className).toEqual('confirmTypeChangeDialog');
    })

    it('should change the type after dialog ok is click', function() {
      var s = sinon.spy();
      spyOn(table, 'changeColumnType');

      view.setTable(table, 'test2');
      view.setColumnTypeChange('boolean');
      view.confirmDialog.ok();

      expect(table.changeColumnType).toHaveBeenCalled();
    })

  })

  describe('when the change is type safe', function() {

    it('should change type without ask for confirmation ', function() {
      var s = sinon.spy();
      spyOn(table, 'changeColumnType');

      view.setTable(table, 'test2');
      view.setColumnTypeChange('string');


      expect(view.confirmDialog).toBeFalsy();
    })

    it('should change the type', function() {
      var s = sinon.spy();
      spyOn(table, 'changeColumnType');

      view.setTable(table, 'test2');
      view.setColumnTypeChange('string');

      expect(table.changeColumnType).toHaveBeenCalled();
    })

  })

});
