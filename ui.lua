local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local localPlayer=assert(Players.LocalPlayer,"stain.best UI requires a client")
local function createUI()
 local Input=game:GetService("UserInputService")
 local library={APIVersion=1,Build=9,Options={},Toggles={},Scheme={},Unloaded=false,signals={},unloads={},CornerRadius=0}
 local C={background=Color3.fromRGB(15,15,15),panel=Color3.fromRGB(18,18,18),control=Color3.fromRGB(23,23,23),edge=Color3.fromRGB(32,32,32),text=Color3.fromRGB(234,234,234),muted=Color3.fromRGB(179,179,179),activeText=Color3.fromRGB(220,112,134),accent=Color3.fromRGB(157,34,61)}
 local gui,window,popup,activeDrag,keyCapture,activeSettings
 local makeSettings
 local popupSignals={}
 local function listen(signal,fn,temporary)local c=signal:Connect(fn);local list=temporary and popupSignals or library.signals;list[#list+1]=c;return c end
 local function new(class,parent,properties)
  local object=Instance.new(class)
  for key,value in pairs(properties or {})do object[key]=value end
  if parent and parent:IsA("GuiObject") and object:IsA("GuiObject") and not(properties and properties.ZIndex)then object.ZIndex=parent.ZIndex end
  object.Parent=parent;return object
 end
 local function frame(parent,properties)
  local values={BorderSizePixel=0,BackgroundColor3=C.panel}
  for key,value in pairs(properties or {})do values[key]=value end
  return new("Frame",parent,values)
 end
 local function label(parent,text,properties)
  local values={BackgroundTransparency=1,BorderSizePixel=0,Text=text or "",TextSize=13,Font=Enum.Font.Code,TextColor3=C.text,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd}
  for key,value in pairs(properties or {})do values[key]=value end
  return new("TextLabel",parent,values)
 end
 local function button(parent,text,properties)
  local values={BorderSizePixel=0,BackgroundColor3=C.control,Text=text or "",TextSize=13,Font=Enum.Font.Code,TextColor3=C.text,AutoButtonColor=false}
  for key,value in pairs(properties or {})do values[key]=value end
  return new("TextButton",parent,values)
 end
 local function edge(object,color)
  return new("UIStroke",object,{Color=color or C.edge,Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
 end
 local function gradient(object,top,bottom)
  -- A UIGradient on a TextButton darkens its text too. Shade a separate backing.
  local target=object
  if object:IsA("TextButton")then
   target=frame(object.Parent,{Name="ControlBackground",Position=object.Position,Size=object.Size,BackgroundColor3=Color3.new(1,1,1),ZIndex=object.ZIndex})
   object.BackgroundTransparency=1
   object.ZIndex=target.ZIndex+1
  end
  new("UIGradient",target,{Rotation=90,Color=ColorSequence.new(top,bottom)})
 end
 local function closePopup()
  for _,c in ipairs(popupSignals)do c:Disconnect()end;table.clear(popupSignals)
  if popup then popup:Destroy();popup=nil;activeDrag=nil end
 end
 local function control(row,default,id,group)
  local value={Value=default,Row=row,Side=group and group.Side,GroupName=group and group.Name}
  function value:OnChanged(callback)self.callback=callback end
  function value:SetValue(v)
   if self.normalize then v=self.normalize(v)end
   self.Value=v;if self.paint then self.paint(v)end
   if self.callback then self.callback(v)end
  end
  function value:SetVisible(v)row.Visible=v end
  if id then library.Options[id]=value end
  return value
 end
 local function popupAt(anchor,width,height)
  closePopup()
  local view=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
  local p=anchor.AbsolutePosition
  popup=frame(gui,{Name="Popup",Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(math.clamp(p.X,4,math.max(4,view.X-width-4)),math.clamp(p.Y+anchor.AbsoluteSize.Y+3,4,math.max(4,view.Y-height-4))),ZIndex=50})
  edge(popup,C.accent)
  return popup
 end
 local function inside(object,p)
  local a,b=object.AbsolutePosition,object.AbsoluteSize
  return p.X>=a.X and p.Y>=a.Y and p.X<=a.X+b.X and p.Y<=a.Y+b.Y
 end
 local function drag(object,callback,temporary)
  listen(object.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
    activeDrag=callback;callback(Vector2.new(input.Position.X,input.Position.Y))
   end
  end,temporary)
 end
 local groups={}
 function groups:row(height)
  if self.ColumnHeights then self.ColumnHeights[self.ColumnName]=self.ColumnHeights[self.ColumnName]+(height or 20)end
  self.order=self.order+1
  return frame(self.Body,{Name="Control",Size=UDim2.new(1,0,0,height or 20),BackgroundTransparency=1,LayoutOrder=self.order})
 end
 function groups:AddToggle(id,info)
  local row=self:row(19)
  local box=button(row,"",{Position=UDim2.fromOffset(2,5),Size=UDim2.fromOffset(9,9)})
  edge(box)
  local text=button(row,info.Text,{BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(20,0),Size=UDim2.new(1,-20,1,0)})
  local value=control(row,info.Default==true,id,self);library.Toggles[id]=value
  value.paint=function(v)box.BackgroundColor3=v and C.accent or C.control;box.BackgroundTransparency=v and 0 or .25 end
  value.paint(value.Value)
  local function click()value:SetValue(not value.Value)end
  listen(box.Activated,click);listen(text.Activated,click)
  function value:AddSettings(title)
   text.Size=UDim2.new(1,-43,1,0)
   self.Settings=makeSettings(row,title or info.Text);return self.Settings
  end
  return value
 end
 function groups:AddSlider(id,info)
  local row=self:row(33)
  label(row,info.Text,{Size=UDim2.new(1,-65,0,16)})
  local number=label(row,"",{Position=UDim2.new(1,-65,0,0),Size=UDim2.fromOffset(65,16),TextXAlignment=Enum.TextXAlignment.Right,TextColor3=C.muted})
  local rail=button(row,"",{Position=UDim2.fromOffset(2,20),Size=UDim2.new(1,-4,0,8)})
  gradient(rail,Color3.fromRGB(25,25,25),Color3.fromRGB(18,18,18));edge(rail)
  local fill=frame(rail,{Size=UDim2.fromScale(0,1),BackgroundColor3=C.accent})
  local value=control(row,info.Default,id,self)
  value.normalize=function(v)
   local scale=10^(info.Rounding or 0)
   return math.clamp(math.floor((tonumber(v)or info.Min)*scale+.5)/scale,info.Min,info.Max)
  end
  value.paint=function(v)number.Text=string.format("%."..tostring(info.Rounding or 0).."f",v);fill.Size=UDim2.fromScale((v-info.Min)/(info.Max-info.Min),1)end
  value.paint(value.Value)
  drag(rail,function(p)if rail.AbsoluteSize.X>0 then value:SetValue(info.Min+math.clamp((p.X-rail.AbsolutePosition.X)/rail.AbsoluteSize.X,0,1)*(info.Max-info.Min))end end)
  return value
 end
 function groups:AddDropdown(id,info)
  local row=self:row(36)
  label(row,info.Text,{Size=UDim2.new(1,0,0,16)})
  local field=button(row,"",{Position=UDim2.fromOffset(2,18),Size=UDim2.new(1,-4,0,16),TextXAlignment=Enum.TextXAlignment.Left})
  gradient(field,Color3.fromRGB(26,26,26),Color3.fromRGB(19,19,19));edge(field)
  label(field,"v",{Position=UDim2.new(1,-14,0,0),Size=UDim2.fromOffset(12,16),TextSize=10})
  local value=control(row,info.Default or info.Values[1],id,self)
  value.paint=function(v)field.Text=" "..tostring(v)end;value.paint(value.Value)
  listen(field.Activated,function()
   local holder=popupAt(field,math.max(120,field.AbsoluteSize.X),#info.Values*19+4)
   for i,item in ipairs(info.Values)do
    local pick=button(holder,tostring(item),{BackgroundColor3=item==value.Value and Color3.fromRGB(39,23,28)or C.control,Position=UDim2.fromOffset(2,2+(i-1)*19),Size=UDim2.new(1,-4,0,19),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51})
    listen(pick.Activated,function()value:SetValue(item);closePopup()end,true)
   end
  end)
  return value
 end
 function groups:AddLabel(text)
  local row=self:row(19)
  local content=label(row,text,{Size=UDim2.new(1,-4,1,0)})
  local value=control(row,text,nil,self)
  function value:SetText(v)content.Text=v end
  function value:AddColorPicker(id,info)
   content.Size=UDim2.new(1,-35,1,0)
   local swatch=button(row,"",{Position=UDim2.new(1,-26,0,5),Size=UDim2.fromOffset(22,9),BackgroundColor3=info.Default});edge(swatch)
   local picker=control(row,info.Default,id)
   picker.paint=function(v)swatch.BackgroundColor3=v end
   listen(swatch.Activated,function()
    local holder=popupAt(row,202,194)
    label(holder,info.Title or "Color",{Position=UDim2.fromOffset(7,2),Size=UDim2.fromOffset(185,18),TextColor3=C.accent,ZIndex=51})
    local h,s,v=picker.Value:ToHSV()
    local square=button(holder,"",{Position=UDim2.fromOffset(8,25),Size=UDim2.fromOffset(160,135),BackgroundColor3=Color3.fromHSV(h,1,1),ZIndex=51})
    local white=frame(square,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(1,1,1),ZIndex=52})
    new("UIGradient",white,{Transparency=NumberSequence.new(0,1)})
    local black=frame(square,{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),ZIndex=53})
    new("UIGradient",black,{Rotation=90,Transparency=NumberSequence.new(1,0)})
    local cursor=frame(square,{Size=UDim2.fromOffset(4,4),AnchorPoint=Vector2.new(.5,.5),BackgroundTransparency=1,ZIndex=54});edge(cursor,Color3.new(1,1,1))
    local hue=button(holder,"",{Position=UDim2.fromOffset(178,25),Size=UDim2.fromOffset(15,135),BackgroundColor3=Color3.new(1,1,1),ZIndex=51})
    local keys={};for i=0,6 do keys[#keys+1]=ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))end
    new("UIGradient",hue,{Rotation=90,Color=ColorSequence.new(keys)})
    local readout=label(holder,"",{Position=UDim2.fromOffset(8,168),Size=UDim2.fromOffset(185,18),ZIndex=51})
    local function update()
     local color=Color3.fromHSV(h,s,v);picker:SetValue(color);square.BackgroundColor3=Color3.fromHSV(h,1,1)
     cursor.Position=UDim2.fromScale(s,1-v)
     readout.Text=string.format("RGB  %d  %d  %d",math.floor(color.R*255+.5),math.floor(color.G*255+.5),math.floor(color.B*255+.5))
    end
    update()
    drag(square,function(p)s=math.clamp((p.X-square.AbsolutePosition.X)/square.AbsoluteSize.X,0,1);v=1-math.clamp((p.Y-square.AbsolutePosition.Y)/square.AbsoluteSize.Y,0,1);update()end,true)
    drag(hue,function(p)h=math.clamp((p.Y-hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y,0,1);update()end,true)
   end)
   return value
  end
  function value:AddKeyPicker(id,info)
   content.Size=UDim2.new(1,-95,1,0)
   local function displayKey(v)return v:gsub("MouseButton","M")end
   local field=button(row,"["..displayKey(info.Default).."]",{BackgroundTransparency=1,Position=UDim2.new(1,-95,0,0),Size=UDim2.fromOffset(95,19),TextXAlignment=Enum.TextXAlignment.Right})
   local bind=control(row,info.Default,id)
   bind.paint=function(v)field.Text="["..displayKey(v).."]"end
   listen(field.Activated,function()field.Text="[...]";keyCapture=bind end)
   return value
  end
  return value
 end
 function groups:AddButton(info,callback)
  if type(info)=="string"then info={Text=info,Func=callback}end
  local row=self:row(23)
  local object=button(row,info.Text,{Position=UDim2.fromOffset(2,2),Size=UDim2.new(1,-4,0,18)})
  gradient(object,Color3.fromRGB(26,26,26),Color3.fromRGB(19,19,19));edge(object)
  listen(object.Activated,info.Func)
  return control(row,nil,nil,self)
 end
 local function closeSettings()
  if activeSettings then activeSettings.Visible=false;activeSettings=nil end
  closePopup()
 end
 makeSettings=function(row,title)
  local shell=frame(gui,{Name="SettingsPopover",Size=UDim2.fromOffset(272,45),Visible=false,ZIndex=30})
  edge(shell,C.accent)
  label(shell,title,{Position=UDim2.fromOffset(7,1),Size=UDim2.new(1,-30,0,21),TextColor3=C.text,ZIndex=31})
  local close=button(shell,"x",{BackgroundTransparency=1,Position=UDim2.new(1,-23,0,1),Size=UDim2.fromOffset(20,20),ZIndex=31})
  local body=new("ScrollingFrame",shell,{Position=UDim2.fromOffset(6,24),Size=UDim2.new(1,-12,1,-29),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true,ZIndex=31})
  new("UIListLayout",body,{SortOrder=Enum.SortOrder.LayoutOrder})
  new("UIPadding",body,{PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})
  local settings=setmetatable({Body=body,order=0,Name=title,Side="Popover",Shell=shell,Owner=row,height=0},{__index=groups})
  local baseRow=groups.row
  function settings:row(height)
   local result=baseRow(self,height)
   self.height=self.height+(height or 20)
   local view=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
   shell.Size=UDim2.fromOffset(272,math.min(self.height+32,math.max(160,view.Y-20)))
   return result
  end
  local cog=button(row,"",{Name="SettingsCog",BackgroundTransparency=1,Position=UDim2.new(1,-20,0,0),Size=UDim2.fromOffset(19,19),TextSize=15,Font=Enum.Font.SourceSans,TextColor3=C.muted})
  -- Draw a monochrome cog; a Unicode gear renders as a colored emoji on some clients.
  local ring=frame(cog,{Name="CogRing",Position=UDim2.fromOffset(9.5,9.5),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(6,6),BackgroundTransparency=1})
  new("UICorner",ring,{CornerRadius=UDim.new(1,0)});edge(ring,C.muted)
  for i=0,7 do
   local angle=i*math.pi/4
   frame(cog,{Position=UDim2.fromOffset(9.5+math.cos(angle)*4,9.5+math.sin(angle)*4),AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(1,3),Rotation=math.deg(angle)+90,BackgroundColor3=C.muted})
  end
  listen(close.Activated,closeSettings)
  listen(cog.Activated,function()
   if activeSettings==shell then closeSettings();return end
   closeSettings()
   local view=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
   local x=window.AbsolutePosition.X+window.AbsoluteSize.X+8
   if x+272>view.X-8 then x=window.AbsolutePosition.X-280 end
   shell.Position=UDim2.fromOffset(math.clamp(x,4,math.max(4,view.X-276)),math.clamp(row.AbsolutePosition.Y,4,math.max(4,view.Y-shell.AbsoluteSize.Y-4)))
   shell.Visible=true;activeSettings=shell;library.SettingsOwner=row
  end)
  return settings
 end
 function library:IsCapturingInput()return keyCapture~=nil end
 function library:WasCaptured(input)return self.LastCapturedInput==input end
 function library:UpdateColorsUsingRegistry()end
 function library:OnUnload(callback)self.unloads[#self.unloads+1]=callback end
 function library:Unload()
  if self.Unloaded then return end
  self.Unloaded=true
  closeSettings()
  for _,c in ipairs(self.signals)do c:Disconnect()end
  table.clear(self.signals)
  for _,callback in ipairs(self.unloads)do pcall(callback)end
  if gui then gui:Destroy()end
 end
 function library:CreateWindow(info)
  gui=new("ScreenGui",localPlayer:WaitForChild("PlayerGui"),{Name="stain.best.Menu",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=100,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
  self.ScreenGui=gui
  local view=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
  local width,height=math.min(info.Width or 540,math.max(300,view.X-24)),math.min(info.Height or 610,math.max(320,view.Y-60))
  window=frame(gui,{Name="Window",Size=UDim2.fromOffset(width,height),Position=UDim2.fromOffset(math.max(12,(view.X-width)*.5),math.max(30,(view.Y-height)*.5)),BackgroundColor3=C.background})
  edge(window,Color3.fromRGB(43,43,43))
  frame(window,{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.accent})
  local title=label(window,'<font color="#dc7086">stain.best</font>',{Position=UDim2.fromOffset(10,5),Size=UDim2.new(1,-40,0,23),TextSize=12,TextColor3=C.text,RichText=true,Active=true})
  local close=button(window,"x",{BackgroundTransparency=1,Position=UDim2.new(1,-25,0,3),Size=UDim2.fromOffset(20,20),TextColor3=C.muted})
  listen(close.Activated,function()library:Unload()end)
  local startMouse,startPosition
  drag(title,function(p)
   if not startMouse then startMouse=p;startPosition=window.Position end
   local dx,dy=p.X-startMouse.X,p.Y-startMouse.Y
   window.Position=UDim2.fromOffset(math.clamp(startPosition.X.Offset+dx,0,math.max(0,view.X-width)),math.clamp(startPosition.Y.Offset+dy,0,math.max(0,view.Y-25)))
  end)
  local tabStrip=frame(window,{Position=UDim2.fromOffset(7,34),Size=UDim2.new(1,-14,0,25),BackgroundColor3=Color3.fromRGB(19,19,19)})
  edge(tabStrip)
  new("UIListLayout",tabStrip,{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder})
  local tabs,selected={},nil
  local result={}
  function result:AddTab(name)
   local index=#tabs+1
   local tabButton=button(tabStrip,name,{Size=UDim2.fromOffset(104,25),TextColor3=C.muted,LayoutOrder=index})
   local page=frame(window,{Position=UDim2.fromOffset(7,68),Size=UDim2.new(1,-14,1,-76),BackgroundTransparency=1,Visible=false})
   local function column(x)
    local columnFrame=new("ScrollingFrame",page,{Position=UDim2.new(x,x==0 and 0 or 4,0,0),Size=UDim2.new(info.SingleColumn and 1 or .5,info.SingleColumn and 0 or -4,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=C.accent,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true})
    new("UIListLayout",columnFrame,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
    new("UIPadding",columnFrame,{PaddingLeft=UDim.new(0,2),PaddingRight=UDim.new(0,4),PaddingBottom=UDim.new(0,4)})
    return columnFrame
   end
   if not info.SingleColumn then frame(page,{Name="ColumnDivider",Position=UDim2.new(.5,0,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=Color3.fromRGB(30,30,30)})end
   local left=column(0)
   local right=info.SingleColumn and left or column(.5)
   local tab={left=left,right=right,order=0,heights={Left=0,Right=0}}
   local function group(side,name)
    tab.order=tab.order+1
    tab.heights[side]=tab.heights[side]+33
    local holder=frame(side=="Left"and left or right,{Name=name,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=tab.order})
    edge(holder,Color3.fromRGB(27,27,27))
    local strip=frame(holder,{Name="SectionHeader",Size=UDim2.new(1,0,0,20),BackgroundColor3=Color3.new(1,1,1)})
    gradient(strip,Color3.fromRGB(28,28,28),Color3.fromRGB(18,18,18))
    label(strip,name,{Position=UDim2.fromOffset(6,0),Size=UDim2.new(1,-12,0,20),TextColor3=C.text})
    local body=frame(holder,{Position=UDim2.fromOffset(6,21),Size=UDim2.new(1,-12,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1})
    new("UIListLayout",body,{SortOrder=Enum.SortOrder.LayoutOrder})
    new("UIPadding",body,{PaddingBottom=UDim.new(0,5)})
    return setmetatable({Body=body,order=0,Name=name,Side=side,ColumnHeights=tab.heights,ColumnName=side},{__index=groups})
   end
   function tab:AddLeftGroupbox(name)return group("Left",name)end
   function tab:AddRightGroupbox(name)return group("Right",name)end
   local record={button=tabButton,page=page,tab=tab};tabs[index]=record
   local function select()
    closeSettings()
    for _,t in ipairs(tabs)do t.page.Visible=t==record;t.button.TextColor3=t==record and C.activeText or C.muted end
    selected=record
   end
   listen(tabButton.Activated,select)
   if not selected then select()end
   return tab
  end

  function result:FitToContent()
   if not selected then return end
   local h=selected.tab.heights
   height=math.clamp(math.max(h.Left,h.Right)+76,320,math.max(320,view.Y-60))
   window.Size=UDim2.fromOffset(width,height)
   local current=window.Position
   window.Position=UDim2.fromOffset(current.X.Offset,math.clamp(current.Y.Offset,0,math.max(0,view.Y-height)))
  end
  listen(Input.InputChanged,function(input)
   if activeDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then activeDrag(Vector2.new(input.Position.X,input.Position.Y))end
  end)
  listen(Input.InputEnded,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then activeDrag=nil;startMouse=nil end
  end)
  listen(Input.InputBegan,function(input,processed)
   local kind=tostring(input.UserInputType):match("[^.]+$")
   if keyCapture and(kind=="Keyboard"or kind=="MouseButton1"or kind=="MouseButton2"or kind=="MouseButton3")then
    local bind=keyCapture;keyCapture=nil;library.LastCapturedInput=input
    if input.KeyCode==Enum.KeyCode.Escape then bind.paint(bind.Value)
    else bind:SetValue(kind=="Keyboard"and input.KeyCode.Name or kind)end
    return
   end
   if input.UserInputType==Enum.UserInputType.Keyboard then
    if not processed and not Input:GetFocusedTextBox()then
     local bind=library.ToggleKeybind
     if input.KeyCode.Name==(bind and bind.Value or "RightShift")then library.LastCapturedInput=input;window.Visible=not window.Visible;closeSettings()end
    end
   elseif kind=="MouseButton1"or kind=="MouseButton2"or kind=="MouseButton3"or kind=="Touch"then
    local bind=library.ToggleKeybind
    if not processed and bind and bind.Value==kind then library.LastCapturedInput=input;window.Visible=not window.Visible;closeSettings();return end
    local point=Vector2.new(input.Position.X,input.Position.Y)
    local inPopup=popup and inside(popup,point)
    if popup and not inPopup then closePopup()end
    if activeSettings and not inPopup and not inside(activeSettings,point) and not inside(library.SettingsOwner,point)then closeSettings()end
   end
  end)
  return result
 end
 return library
end
return createUI()

